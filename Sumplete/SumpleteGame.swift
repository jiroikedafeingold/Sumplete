//
//  SumpleteGame.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import Foundation

// MARK: - Cell State

enum CellState: Int, Codable {
    case blank    // Unknown - default
    case deleted  // Red X - marked for deletion
    case kept     // Green circle - marked to keep
}

// MARK: - Difficulty

enum Difficulty: String, CaseIterable {
    case easy
    case medium
    case hard
    case expert
    
    /// Fraction of cells that should be deleted from the solution
    var deletionFraction: ClosedRange<Double> {
        switch self {
        case .easy:   return 0.25...0.35
        case .medium: return 0.35...0.50
        case .hard:   return 0.50...0.65
        case .expert: return 0.65...0.75
        }
    }
}

// MARK: - Undo Action

struct UndoAction: Codable {
    let row: Int
    let col: Int
    let previousState: CellState
}

// MARK: - Sumplete Game

class SumpleteGame {
    let size: Int
    let difficulty: Difficulty
    
    /// The numbers displayed in each cell (size x size)
    private(set) var grid: [[Int]]
    
    /// Whether each cell is part of the solution (should be kept)
    private(set) var solution: [[Bool]]
    
    /// Target sums for each row (right side clues)
    private(set) var rowTargets: [Int]
    
    /// Target sums for each column (bottom clues)
    private(set) var colTargets: [Int]
    
    /// Current player state for each cell
    var cellStates: [[CellState]]
    
    /// Undo stack
    var undoStack: [UndoAction] = []
    
    /// Whether the puzzle is solved
    var isSolved: Bool {
        for row in 0..<size {
            if !isRowSolved(row) { return false }
        }
        for col in 0..<size {
            if !isColSolved(col) { return false }
        }
        return true
    }
    
    init(size: Int = 9, difficulty: Difficulty = .easy) {
        self.size = size
        self.difficulty = difficulty
        self.grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        self.solution = Array(repeating: Array(repeating: true, count: size), count: size)
        self.rowTargets = Array(repeating: 0, count: size)
        self.colTargets = Array(repeating: 0, count: size)
        self.cellStates = Array(repeating: Array(repeating: CellState.blank, count: size), count: size)
        generatePuzzle()
    }
    
    // MARK: - Puzzle Generation
    
    private func generatePuzzle() {
        let needMix = size >= 5
        
        // Try up to 100 candidates to find one that is logically solvable
        // and meets our target distribution constraints.
        for _ in 0..<100 {
            // Step 1: Fill grid with random values that include repeats
            fillGridWithRepeats()
            
            // Step 2: Build solution with biased keep counts
            buildBiasedSolution()
            
            // Step 3: Calculate target sums
            calculateTargets()
            
            // Step 4: Target distribution constraints
            let allTargets = rowTargets + colTargets
            let zeroCount = allTargets.filter { $0 == 0 }.count
            let highCount = allTargets.filter { $0 > 45 }.count
            let lowCount = allTargets.filter { $0 <= 10 }.count
            let largeCount = allTargets.filter { $0 >= 30 }.count
            
            let limitsOk = zeroCount <= 2 && highCount <= 2
            let mixOk = !needMix || (lowCount >= 2 && largeCount >= 2)
            
            guard limitsOk && mixOk else { continue }
            
            // Step 5: Verify the puzzle is logically solvable (no guessing needed)
            if Settings.guaranteeLogicSolvable {
                guard isLogicallySolvable() else { continue }
            }
            
            // Found a valid puzzle — done
            break
        }
        
        // Reset cell states
        cellStates = Array(repeating: Array(repeating: CellState.blank, count: size), count: size)
        undoStack.removeAll()
    }
    
    /// Build solution with keep counts biased toward extremes.
    /// This creates a mix of low-target rows (few cells kept, easy to identify deletions)
    /// and high-target rows (most cells kept, easy to identify the few deletions),
    /// with some mid-range rows for variety. The resulting puzzles have more
    /// "entry points" where the player can start reasoning confidently.
    private func buildBiasedSolution() {
        for row in 0..<size {
            let keepCount = biasedKeepCount()
            var cols = Array(0..<size)
            cols.shuffle()
            
            for col in 0..<size {
                solution[row][col] = false
            }
            for i in 0..<keepCount {
                solution[row][cols[i]] = true
            }
        }
    }
    
    /// Returns a keep count biased toward low (0-2) and high (size-3 to size-1) values.
    /// About 35% chance low, 35% chance high, 30% chance mid-range.
    private func biasedKeepCount() -> Int {
        let roll = Double.random(in: 0..<1)
        if size <= 3 {
            // Small grids: just use uniform, not enough room for bias
            return Int.random(in: 0..<size)
        }
        
        let lowMax = min(2, size - 1)           // keep 0, 1, or 2
        let highMin = max(size - 3, lowMax + 1) // keep size-3, size-2, or size-1
        
        if roll < 0.35 {
            // Low: keep few cells → small target sums
            return Int.random(in: 0...lowMax)
        } else if roll < 0.70 {
            // High: keep most cells → large target sums
            return Int.random(in: highMin...(size - 1))
        } else {
            // Mid-range for variety
            let midLow = lowMax + 1
            let midHigh = highMin - 1
            if midLow <= midHigh {
                return Int.random(in: midLow...midHigh)
            } else {
                // Grid too small for a true mid-range, fall back to uniform
                return Int.random(in: 0..<size)
            }
        }
    }
    
    private func calculateTargets() {
        for row in 0..<size {
            rowTargets[row] = 0
            for col in 0..<size {
                if solution[row][col] {
                    rowTargets[row] += grid[row][col]
                }
            }
        }
        for col in 0..<size {
            colTargets[col] = 0
            for row in 0..<size {
                if solution[row][col] {
                    colTargets[col] += grid[row][col]
                }
            }
        }
    }
    
    /// Fill the grid with random values, ensuring at most one low value (1 or 2)
    /// per row and per column. Multiple low values in the same line make
    /// subset-sum deduction very hard because many small-number combinations
    /// produce the same total. Repeated values in the 3-9 range are encouraged
    /// to give players concrete reasoning handles.
    private func fillGridWithRepeats() {
        // Start with all values 3-9
        for row in 0..<size {
            for col in 0..<size {
                grid[row][col] = Int.random(in: 3...9)
            }
        }
        
        // Place at most one low value (1 or 2) per row and per column.
        // Track which columns already have a low value.
        var colHasLow = Array(repeating: false, count: size)
        
        for row in 0..<size {
            // ~40% chance this row gets a low value at all
            guard Bool.random() && Double.random(in: 0..<1) < 0.4 else { continue }
            
            // Pick a column that doesn't already have a low value
            let available = (0..<size).filter { !colHasLow[$0] }
            guard let col = available.randomElement() else { continue }
            
            grid[row][col] = Int.random(in: 1...2)
            colHasLow[col] = true
        }
        
        // Ensure every row and column has at least one repeated value
        // (for grids large enough to benefit from it).
        if size >= 5 {
            for row in 0..<size {
                let values = (0..<size).map { grid[row][$0] }
                if Set(values).count == size {
                    // All unique — force a repeat by copying a non-low value
                    let srcCol = Int.random(in: 0..<size)
                    var destCol = Int.random(in: 0..<(size - 1))
                    if destCol >= srcCol { destCol += 1 }
                    grid[row][destCol] = grid[row][srcCol]
                }
            }
            for col in 0..<size {
                let values = (0..<size).map { grid[$0][col] }
                if Set(values).count == size {
                    let srcRow = Int.random(in: 0..<size)
                    var destRow = Int.random(in: 0..<(size - 1))
                    if destRow >= srcRow { destRow += 1 }
                    grid[destRow][col] = grid[srcRow][col]
                }
            }
        }
    }
    
    // MARK: - Logical Solver
    
    struct Deduction {
        let row: Int
        let col: Int
        let keep: Bool
        let reason: String
    }
    
    /// Returns the next cell that can be logically deduced from the current
    /// player state, along with a human-readable explanation.
    func nextLogicalDeduction() -> Deduction? {
        var state = Array(repeating: Array(repeating: 0, count: size), count: size)
        for r in 0..<size {
            for c in 0..<size {
                switch cellStates[r][c] {
                case .kept:    state[r][c] = 1
                case .deleted: state[r][c] = -1
                case .blank:   state[r][c] = 0
                }
            }
        }
        
        var madeProgress = true
        while madeProgress {
            madeProgress = false
            
            for row in 0..<size {
                let resolved = solveLineCollecting(state: &state, isRow: true,
                                                   index: row, target: rowTargets[row])
                for d in resolved {
                    if cellStates[d.row][d.col] == .blank { return d }
                    madeProgress = true
                }
            }
            
            for col in 0..<size {
                let resolved = solveLineCollecting(state: &state, isRow: false,
                                                   index: col, target: colTargets[col])
                for d in resolved {
                    if cellStates[d.row][d.col] == .blank { return d }
                    madeProgress = true
                }
            }
        }
        
        return nil
    }
    
    private func solveLineCollecting(state: inout [[Int]], isRow: Bool, index: Int,
                                     target: Int) -> [Deduction] {
        var keptSum = 0
        var undecided: [(pos: Int, value: Int)] = []
        
        for i in 0..<size {
            let r = isRow ? index : i
            let c = isRow ? i : index
            switch state[r][c] {
            case 1:  keptSum += grid[r][c]
            case -1: break
            default: undecided.append((i, grid[r][c]))
            }
        }
        
        guard !undecided.isEmpty else { return [] }
        
        let remaining = target - keptSum
        let lineName = isRow ? "Row \(index + 1)" : "Column \(index + 1)"
        var results: [Deduction] = []
        
        if remaining == 0 {
            let reason: String
            if keptSum == 0 {
                reason = "\(lineName) has a target of 0, so all cells must be deleted."
            } else {
                reason = "\(lineName) already reaches its target of \(target). The remaining cells must be deleted."
            }
            for (pos, _) in undecided {
                let r = isRow ? index : pos
                let c = isRow ? pos : index
                if state[r][c] == 0 {
                    state[r][c] = -1
                    results.append(Deduction(row: r, col: c, keep: false, reason: reason))
                }
            }
            return results
        }
        
        let undecidedSum = undecided.reduce(0) { $0 + $1.value }
        if remaining == undecidedSum {
            let reason = "\(lineName) still needs \(remaining) to reach its target of \(target), and the remaining cells sum to exactly \(undecidedSum). All must be kept."
            for (pos, _) in undecided {
                let r = isRow ? index : pos
                let c = isRow ? pos : index
                if state[r][c] == 0 {
                    state[r][c] = 1
                    results.append(Deduction(row: r, col: c, keep: true, reason: reason))
                }
            }
            return results
        }
        
        if remaining < 0 || remaining > undecidedSum { return [] }
        
        let n = undecided.count
        let totalSubsets = 1 << n
        var validCount = 0
        var inAllValid = Array(repeating: true, count: n)
        var inAnyValid = Array(repeating: false, count: n)
        
        for mask in 0..<totalSubsets {
            var subsetSum = 0
            for bit in 0..<n {
                if mask & (1 << bit) != 0 {
                    subsetSum += undecided[bit].value
                }
            }
            if subsetSum == remaining {
                validCount += 1
                for bit in 0..<n {
                    let inSubset = (mask & (1 << bit)) != 0
                    if !inSubset { inAllValid[bit] = false }
                    if inSubset  { inAnyValid[bit] = true }
                }
            }
        }
        
        guard validCount > 0 else { return [] }
        
        for i in 0..<n {
            let pos = undecided[i].pos
            let r = isRow ? index : pos
            let c = isRow ? pos : index
            let cellValue = undecided[i].value
            
            if state[r][c] == 0 {
                if inAllValid[i] {
                    let reason: String
                    if validCount == 1 {
                        reason = "\(lineName) needs \(remaining) more. There's only one combination that works, and it includes this \(cellValue)."
                    } else {
                        reason = "\(lineName) needs \(remaining) more. Every possible combination includes this \(cellValue), so it must be kept."
                    }
                    state[r][c] = 1
                    results.append(Deduction(row: r, col: c, keep: true, reason: reason))
                } else if !inAnyValid[i] {
                    let reason: String
                    if validCount == 1 {
                        reason = "\(lineName) needs \(remaining) more. There's only one combination that works, and it doesn't include this \(cellValue)."
                    } else {
                        reason = "\(lineName) needs \(remaining) more. No valid combination includes this \(cellValue), so it must be deleted."
                    }
                    state[r][c] = -1
                    results.append(Deduction(row: r, col: c, keep: false, reason: reason))
                }
            }
        }
        
        return results
    }
    
    /// Determines whether the current puzzle can be solved purely through
    /// logical deduction (no guessing required). The solver simulates
    /// human reasoning:
    ///
    /// 1. Trivial: if target is 0 → delete all; if target == sum of unknowns → keep all
    /// 2. Subset analysis: for each row/column, enumerate all subsets of
    ///    undecided cells that achieve the remaining target. Cells present
    ///    in EVERY valid subset must be kept; cells in NO valid subset must
    ///    be deleted.
    /// 3. Iterate until no more progress or all cells resolved.
    ///
    /// Because the maximum grid is 9x9, subset enumeration per line is
    /// at most 2^9 = 512, which is instant.
    private func isLogicallySolvable() -> Bool {
        // Working copy of cell states: 0 = undecided, 1 = kept, -1 = deleted
        var state = Array(repeating: Array(repeating: 0, count: size), count: size)
        
        // Calculate targets (they should already be set, but be safe)
        let rTargets = rowTargets
        let cTargets = colTargets
        
        var changed = true
        while changed {
            changed = false
            
            // Process each row
            for row in 0..<size {
                if solveLinePass(state: &state, isRow: true, index: row,
                                 target: rTargets[row]) {
                    changed = true
                }
            }
            
            // Process each column
            for col in 0..<size {
                if solveLinePass(state: &state, isRow: false, index: col,
                                 target: cTargets[col]) {
                    changed = true
                }
            }
        }
        
        // Check if all cells are resolved
        for row in 0..<size {
            for col in 0..<size {
                if state[row][col] == 0 { return false }
            }
        }
        return true
    }
    
    /// Attempt to resolve undecided cells in a single row or column.
    /// Returns true if at least one cell was resolved.
    private func solveLinePass(state: inout [[Int]], isRow: Bool, index: Int,
                               target: Int) -> Bool {
        // Gather undecided cell positions and their grid values,
        // plus the sum of already-kept cells.
        var keptSum = 0
        var undecided: [(pos: Int, value: Int)] = []   // pos = col (if row) or row (if col)
        
        for i in 0..<size {
            let r = isRow ? index : i
            let c = isRow ? i : index
            
            switch state[r][c] {
            case 1:  keptSum += grid[r][c]   // already kept
            case -1: break                    // already deleted
            default: undecided.append((i, grid[r][c]))
            }
        }
        
        guard !undecided.isEmpty else { return false }
        
        let remaining = target - keptSum
        
        // Quick trivial checks
        if remaining == 0 {
            // All undecided cells must be deleted
            var changed = false
            for (pos, _) in undecided {
                let r = isRow ? index : pos
                let c = isRow ? pos : index
                state[r][c] = -1
                changed = true
            }
            return changed
        }
        
        let undecidedSum = undecided.reduce(0) { $0 + $1.value }
        if remaining == undecidedSum {
            // All undecided cells must be kept
            var changed = false
            for (pos, _) in undecided {
                let r = isRow ? index : pos
                let c = isRow ? pos : index
                state[r][c] = 1
                changed = true
            }
            return changed
        }
        
        // If remaining is negative or exceeds undecided sum, puzzle is broken
        // (shouldn't happen with valid generation, but guard against it)
        if remaining < 0 || remaining > undecidedSum { return false }
        
        // Subset enumeration: find all subsets of undecided cells that sum to `remaining`
        let n = undecided.count
        let totalSubsets = 1 << n
        
        // Track how many valid subsets each cell appears in
        var validCount = 0
        var inAllValid = Array(repeating: true, count: n)   // in every valid subset?
        var inAnyValid = Array(repeating: false, count: n)  // in at least one valid subset?
        
        for mask in 0..<totalSubsets {
            var subsetSum = 0
            for bit in 0..<n {
                if mask & (1 << bit) != 0 {
                    subsetSum += undecided[bit].value
                }
            }
            if subsetSum == remaining {
                validCount += 1
                for bit in 0..<n {
                    let inSubset = (mask & (1 << bit)) != 0
                    if !inSubset { inAllValid[bit] = false }
                    if inSubset  { inAnyValid[bit] = true }
                }
            }
        }
        
        // No valid subsets means something went wrong — can't resolve
        guard validCount > 0 else { return false }
        
        var changed = false
        for i in 0..<n {
            let pos = undecided[i].pos
            let r = isRow ? index : pos
            let c = isRow ? pos : index
            
            if inAllValid[i] {
                // This cell is in EVERY valid subset → must be kept
                state[r][c] = 1
                changed = true
            } else if !inAnyValid[i] {
                // This cell is in NO valid subset → must be deleted
                state[r][c] = -1
                changed = true
            }
        }
        
        return changed
    }
    
    // MARK: - Cell Interaction
    
    /// Cycle cell state: blank -> deleted -> kept -> blank
    func cycleCell(row: Int, col: Int) {
        let previous = cellStates[row][col]
        undoStack.append(UndoAction(row: row, col: col, previousState: previous))
        
        switch cellStates[row][col] {
        case .blank:
            cellStates[row][col] = .deleted
        case .deleted:
            cellStates[row][col] = .kept
        case .kept:
            cellStates[row][col] = .blank
        }
    }
    
    /// Undo last action
    func undo() -> UndoAction? {
        guard let action = undoStack.popLast() else { return nil }
        cellStates[action.row][action.col] = action.previousState
        return action
    }
    
    /// Clear all cell states
    func clearAll() {
        for row in 0..<size {
            for col in 0..<size {
                cellStates[row][col] = .blank
            }
        }
        undoStack.removeAll()
    }
    
    // MARK: - Validation
    
    /// Sum of non-deleted cells in a row (blank cells count as kept for sum purposes)
    func currentRowSum(_ row: Int) -> Int {
        var sum = 0
        for col in 0..<size {
            if cellStates[row][col] != .deleted {
                sum += grid[row][col]
            }
        }
        return sum
    }
    
    /// Sum of non-deleted cells in a column
    func currentColSum(_ col: Int) -> Int {
        var sum = 0
        for row in 0..<size {
            if cellStates[row][col] != .deleted {
                sum += grid[row][col]
            }
        }
        return sum
    }
    
    /// Whether the current non-deleted sum matches the target (ignores blank vs kept)
    func rowSumMatches(_ row: Int) -> Bool {
        return currentRowSum(row) == rowTargets[row]
    }
    
    /// Whether the current non-deleted sum matches the target (ignores blank vs kept)
    func colSumMatches(_ col: Int) -> Bool {
        return currentColSum(col) == colTargets[col]
    }
    
    /// Check if a row is fully solved (all cells decided AND sum matches)
    func isRowSolved(_ row: Int) -> Bool {
        for col in 0..<size {
            if cellStates[row][col] == .blank { return false }
        }
        return currentRowSum(row) == rowTargets[row]
    }
    
    /// Check if a column is fully solved (all cells decided AND sum matches)
    func isColSolved(_ col: Int) -> Bool {
        for row in 0..<size {
            if cellStates[row][col] == .blank { return false }
        }
        return currentColSum(col) == colTargets[col]
    }
    
    /// Auto-mark remaining blank cells in a row when clue is tapped.
    /// If target is 0, all blank cells are deleted.
    /// If remaining blank cells' sum equals the amount still needed, they are all kept.
    func autoMarkRow(_ row: Int) {
        var blankCols: [Int] = []
        for col in 0..<size {
            if cellStates[row][col] == .blank {
                blankCols.append(col)
            }
        }
        guard !blankCols.isEmpty else { return }
        
        let blankSum = blankCols.reduce(0) { $0 + grid[row][$1] }
        let currentKeptSum = currentRowSum(row)
        let surplus = currentKeptSum - rowTargets[row]
        
        if surplus == blankSum {
            // All remaining blank cells should be deleted
            for col in blankCols {
                undoStack.append(UndoAction(row: row, col: col, previousState: .blank))
                cellStates[row][col] = .deleted
            }
        } else if surplus == 0 {
            // All remaining blank cells should be kept
            for col in blankCols {
                undoStack.append(UndoAction(row: row, col: col, previousState: .blank))
                cellStates[row][col] = .kept
            }
        }
    }
    
    /// Auto-mark remaining blank cells in a column when clue is tapped.
    /// If target is 0, all blank cells are deleted.
    /// If remaining blank cells' sum equals the amount still needed, they are all kept.
    func autoMarkCol(_ col: Int) {
        var blankRows: [Int] = []
        for row in 0..<size {
            if cellStates[row][col] == .blank {
                blankRows.append(row)
            }
        }
        guard !blankRows.isEmpty else { return }
        
        let blankSum = blankRows.reduce(0) { $0 + grid[$1][col] }
        let currentKeptSum = currentColSum(col)
        let surplus = currentKeptSum - colTargets[col]
        
        if surplus == blankSum {
            // All remaining blank cells should be deleted
            for row in blankRows {
                undoStack.append(UndoAction(row: row, col: col, previousState: .blank))
                cellStates[row][col] = .deleted
            }
        } else if surplus == 0 {
            // All remaining blank cells should be kept
            for row in blankRows {
                undoStack.append(UndoAction(row: row, col: col, previousState: .blank))
                cellStates[row][col] = .kept
            }
        }
    }
    
    /// Start a new puzzle with same settings
    func newGame() {
        self.grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        self.solution = Array(repeating: Array(repeating: true, count: size), count: size)
        self.rowTargets = Array(repeating: 0, count: size)
        self.colTargets = Array(repeating: 0, count: size)
        self.cellStates = Array(repeating: Array(repeating: CellState.blank, count: size), count: size)
        self.undoStack.removeAll()
        generatePuzzle()
    }
    
    // MARK: - Save / Restore
    
    private struct SaveData: Codable {
        let size: Int
        let difficulty: String
        let grid: [[Int]]
        let solution: [[Bool]]
        let rowTargets: [Int]
        let colTargets: [Int]
        let cellStates: [[CellState]]
        let undoStack: [UndoAction]
    }
    
    private static let saveKey = "savedGame"
    
    /// Save the current game state to UserDefaults
    func save() {
        let data = SaveData(
            size: size,
            difficulty: difficulty.rawValue,
            grid: grid,
            solution: solution,
            rowTargets: rowTargets,
            colTargets: colTargets,
            cellStates: cellStates,
            undoStack: undoStack
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: SumpleteGame.saveKey)
        }
    }
    
    /// Remove any saved game
    static func clearSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
    
    /// Restore a saved game, or return nil if no save exists
    static func restore() -> SumpleteGame? {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(SaveData.self, from: data),
              let diff = Difficulty(rawValue: saved.difficulty) else {
            return nil
        }
        
        let game = SumpleteGame(restored: true, size: saved.size, difficulty: diff)
        game.grid = saved.grid
        game.solution = saved.solution
        game.rowTargets = saved.rowTargets
        game.colTargets = saved.colTargets
        game.cellStates = saved.cellStates
        game.undoStack = saved.undoStack
        return game
    }
    
    /// Private initializer that skips puzzle generation (for restoring saved games)
    private init(restored: Bool, size: Int, difficulty: Difficulty) {
        self.size = size
        self.difficulty = difficulty
        self.grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        self.solution = Array(repeating: Array(repeating: true, count: size), count: size)
        self.rowTargets = Array(repeating: 0, count: size)
        self.colTargets = Array(repeating: 0, count: size)
        self.cellStates = Array(repeating: Array(repeating: CellState.blank, count: size), count: size)
    }
}

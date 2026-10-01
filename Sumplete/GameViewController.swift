//
//  GameViewController.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import StoreKit
import UIKit

class GameViewController: UIViewController {
    
    // MARK: - Properties
    
    private var game: SumpleteGame!
    private var cellViews: [[GridCellView]] = []
    private var rowClueViews: [ClueLabelView] = []
    private var colClueViews: [ClueLabelView] = []
    
    private let gridContainer = UIView()
    private let timerLabel = UILabel()
    private let titleLabel = UILabel()
    private let sizeSelector = UISegmentedControl()
    private let toolbar = UIStackView()
    private let newPuzzleButton = UIButton()
    
    private var currentSize: Int = 9
    
    private let horizontalSeparator = UIView()
    private let verticalSeparator = UIView()
    
    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    private var gameCompleted = false
    private var hintsUsedThisGame = 0
    private var checksUsedThisGame = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Try to restore a saved game
        if let saved = SumpleteGame.restore(),
           let savedMeta = GameViewController.restoreMeta() {
            game = saved
            currentSize = saved.size
            elapsedSeconds = savedMeta.elapsedSeconds
            hintsUsedThisGame = savedMeta.hintsUsed
            checksUsedThisGame = savedMeta.checksUsed
            gameCompleted = savedMeta.gameCompleted
            StatsManager.shared.currentSize = currentSize
            SumpleteGame.clearSave()
        } else {
            game = SumpleteGame(size: currentSize, difficulty: .easy)
            StatsManager.shared.currentSize = currentSize
        }
        
        setupUI()
        sizeSelector.selectedSegmentIndex = currentSize - 3
        buildGrid()
        updateClueStates()
        updateTimerLabel()
        if !gameCompleted {
            startTimer()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            newPuzzleButton.layer.borderColor = UIColor.systemBlue.cgColor
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Title
        titleLabel.text = "$umplete"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Size selector
        for (i, size) in (3...9).enumerated() {
            sizeSelector.insertSegment(withTitle: "\(size)x\(size)", at: i, animated: false)
        }
        sizeSelector.selectedSegmentIndex = currentSize - 3
        sizeSelector.addTarget(self, action: #selector(sizeChanged(_:)), for: .valueChanged)
        sizeSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sizeSelector)
        
        // Timer
        timerLabel.text = "00:00"
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        timerLabel.textColor = .secondaryLabel
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        // Grid container
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridContainer)
        
        // Toolbar — 4 action buttons
        toolbar.axis = .horizontal
        toolbar.spacing = 10
        toolbar.alignment = .center
        toolbar.distribution = .fillEqually
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        let checkButton = makeToolbarButton(
            title: "Check", systemImage: "checkmark.circle", action: #selector(checkTapped)
        )
        let hintButton = makeToolbarButton(
            title: "Hint", systemImage: "lightbulb.fill", action: #selector(hintTapped)
        )
        let revealButton = makeToolbarButton(
            title: "Reveal", systemImage: "eye.fill", action: #selector(revealTapped)
        )
        let undoButton = makeToolbarButton(
            title: "Undo", systemImage: "arrow.uturn.backward", action: #selector(undoTapped)
        )
        
        toolbar.addArrangedSubview(checkButton)
        toolbar.addArrangedSubview(hintButton)
        toolbar.addArrangedSubview(revealButton)
        toolbar.addArrangedSubview(undoButton)
        
        // New Puzzle button — prominent filled style
        var npConfig = UIButton.Configuration.filled()
        npConfig.title = "New Puzzle"
        npConfig.baseBackgroundColor = .systemBlue
        npConfig.baseForegroundColor = .white
        npConfig.cornerStyle = .large
        npConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return out
        }
        npConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 32, bottom: 12, trailing: 32)
        newPuzzleButton.configuration = npConfig
        newPuzzleButton.addTarget(self, action: #selector(newGameTapped), for: .touchUpInside)
        newPuzzleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPuzzleButton)
        
        // Wrapper stack to vertically center all content
        let wrapperStack = UIStackView(arrangedSubviews: [titleLabel, sizeSelector, timerLabel, gridContainer, toolbar, newPuzzleButton])
        wrapperStack.axis = .vertical
        wrapperStack.alignment = .center
        wrapperStack.spacing = 10
        wrapperStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wrapperStack)
        
        // Custom spacing within the wrapper
        wrapperStack.setCustomSpacing(8, after: titleLabel)
        wrapperStack.setCustomSpacing(8, after: sizeSelector)
        wrapperStack.setCustomSpacing(12, after: timerLabel)
        wrapperStack.setCustomSpacing(14, after: gridContainer)
        wrapperStack.setCustomSpacing(14, after: toolbar)
        
        NSLayoutConstraint.activate([
            // Pin to safe area top/bottom so the grid can expand vertically
            wrapperStack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            wrapperStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            wrapperStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wrapperStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            wrapperStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 8),
            wrapperStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -8),
            
            // Grid stays within the wrapper but doesn't force it wider
            gridContainer.leadingAnchor.constraint(greaterThanOrEqualTo: wrapperStack.leadingAnchor),
            gridContainer.trailingAnchor.constraint(lessThanOrEqualTo: wrapperStack.trailingAnchor),
            gridContainer.centerXAnchor.constraint(equalTo: wrapperStack.centerXAnchor),
            
            // Toolbar matches grid width
            toolbar.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: 4),
            toolbar.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor, constant: -4),
        ])
        
        // The wrapper should try to fill the width (iPhone) but never exceed the screen
        let fillWidth = wrapperStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -16)
        fillWidth.priority = .defaultHigh
        fillWidth.isActive = true
        
        // Grid should try to fill the wrapper width, but can shrink if height-constrained
        let gridFillWidth = gridContainer.widthAnchor.constraint(equalTo: wrapperStack.widthAnchor)
        gridFillWidth.priority = .defaultHigh
        gridFillWidth.isActive = true
    }
    
    private func makeToolbarButton(title: String, systemImage: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.image = UIImage(systemName: systemImage)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        config.imagePlacement = .top
        config.imagePadding = 4
        config.cornerStyle = .medium
        config.baseForegroundColor = .label
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            return out
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Grid Building
    
    private func buildGrid() {
        gridContainer.subviews.forEach { $0.removeFromSuperview() }
        cellViews.removeAll()
        rowClueViews.removeAll()
        colClueViews.removeAll()
        
        let size = game.size
        let gridSpacing: CGFloat = 3
        let separatorThickness: CGFloat = 1
        let separatorGap: CGFloat = 4  // gap between grid and clue area
        
        // -- Main game grid (size x size cells, fillEqually) --
        let gameGrid = UIStackView()
        gameGrid.axis = .vertical
        gameGrid.spacing = gridSpacing
        gameGrid.alignment = .fill
        gameGrid.distribution = .fillEqually
        gameGrid.translatesAutoresizingMaskIntoConstraints = false
        
        for row in 0..<size {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = gridSpacing
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually
            gameGrid.addArrangedSubview(rowStack)
            
            var rowCells: [GridCellView] = []
            for col in 0..<size {
                let cell = GridCellView()
                cell.number = game.grid[row][col]
                cell.state = game.cellStates[row][col]
                cell.row = row
                cell.col = col
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
                cell.addGestureRecognizer(tap)
                
                rowStack.addArrangedSubview(cell)
                rowCells.append(cell)
            }
            cellViews.append(rowCells)
        }
        
        // -- Right clue column (size row clues, stacked vertically) --
        let rightClueStack = UIStackView()
        rightClueStack.axis = .vertical
        rightClueStack.spacing = gridSpacing
        rightClueStack.alignment = .fill
        rightClueStack.distribution = .fillEqually
        rightClueStack.translatesAutoresizingMaskIntoConstraints = false
        
        for row in 0..<size {
            let clue = ClueLabelView()
            clue.target = game.rowTargets[row]
            clue.isRowClue = true
            clue.index = row
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(rowClueTapped(_:)))
            clue.addGestureRecognizer(tap)
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(rowClueLongPressed(_:)))
            longPress.minimumPressDuration = 0.3
            clue.addGestureRecognizer(longPress)
            
            rightClueStack.addArrangedSubview(clue)
            rowClueViews.append(clue)
        }
        
        // -- Bottom clue row (size column clues, stacked horizontally) --
        let bottomClueStack = UIStackView()
        bottomClueStack.axis = .horizontal
        bottomClueStack.spacing = gridSpacing
        bottomClueStack.alignment = .fill
        bottomClueStack.distribution = .fillEqually
        bottomClueStack.translatesAutoresizingMaskIntoConstraints = false
        
        for col in 0..<size {
            let clue = ClueLabelView()
            clue.target = game.colTargets[col]
            clue.isRowClue = false
            clue.index = col
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(colClueTapped(_:)))
            clue.addGestureRecognizer(tap)
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(colClueLongPressed(_:)))
            longPress.minimumPressDuration = 0.3
            clue.addGestureRecognizer(longPress)
            
            bottomClueStack.addArrangedSubview(clue)
            colClueViews.append(clue)
        }
        
        // -- Separator lines --
        horizontalSeparator.removeFromSuperview()
        verticalSeparator.removeFromSuperview()
        horizontalSeparator.backgroundColor = .systemGray
        verticalSeparator.backgroundColor = .systemGray
        horizontalSeparator.translatesAutoresizingMaskIntoConstraints = false
        verticalSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        // -- Add everything to gridContainer --
        gridContainer.addSubview(gameGrid)
        gridContainer.addSubview(verticalSeparator)
        gridContainer.addSubview(rightClueStack)
        gridContainer.addSubview(horizontalSeparator)
        gridContainer.addSubview(bottomClueStack)
        
        // The clue labels are roughly the width of one cell.
        // Cell width = (totalWidth - rightClueWidth - separatorGap - (size-1)*gridSpacing) / size
        // We want rightClueWidth ≈ cell width, so:
        //   rightClueWidth = (totalWidth - separatorGap - (size-1)*gridSpacing) / (size + 1)
        // This makes clue columns the same width as grid cells but separated by a visible line.
        
        let clueWidthFraction = 1.0 / CGFloat(size + 1)
        
        NSLayoutConstraint.activate([
            // Game grid: top-left, square cells
            gameGrid.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            gameGrid.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
            gameGrid.bottomAnchor.constraint(equalTo: horizontalSeparator.topAnchor, constant: -separatorGap / 2),
            gameGrid.trailingAnchor.constraint(equalTo: verticalSeparator.leadingAnchor, constant: -separatorGap / 2),
            
            // Vertical separator
            verticalSeparator.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            verticalSeparator.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor),
            verticalSeparator.widthAnchor.constraint(equalToConstant: separatorThickness),
            
            // Right clue stack: aligned with game grid rows
            rightClueStack.topAnchor.constraint(equalTo: gameGrid.topAnchor),
            rightClueStack.bottomAnchor.constraint(equalTo: gameGrid.bottomAnchor),
            rightClueStack.leadingAnchor.constraint(equalTo: verticalSeparator.trailingAnchor, constant: separatorGap / 2),
            rightClueStack.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor),
            rightClueStack.widthAnchor.constraint(equalTo: gridContainer.widthAnchor, multiplier: clueWidthFraction),
            
            // Horizontal separator
            horizontalSeparator.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
            horizontalSeparator.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor),
            horizontalSeparator.heightAnchor.constraint(equalToConstant: separatorThickness),
            
            // Bottom clue stack: aligned with game grid columns
            bottomClueStack.topAnchor.constraint(equalTo: horizontalSeparator.bottomAnchor, constant: separatorGap / 2),
            bottomClueStack.leadingAnchor.constraint(equalTo: gameGrid.leadingAnchor),
            bottomClueStack.trailingAnchor.constraint(equalTo: gameGrid.trailingAnchor),
            bottomClueStack.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor),
            bottomClueStack.heightAnchor.constraint(equalTo: gridContainer.heightAnchor, multiplier: clueWidthFraction),
            
            // Overall square aspect ratio
            gridContainer.heightAnchor.constraint(equalTo: gridContainer.widthAnchor),
        ])
    }
    
    // MARK: - Cell Interaction
    
    @objc private func cellTapped(_ gesture: UITapGestureRecognizer) {
        guard !gameCompleted, let cell = gesture.view as? GridCellView else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        game.cycleCell(row: cell.row, col: cell.col)
        cell.state = game.cellStates[cell.row][cell.col]
        
        updateClueStates()
        checkWinCondition()
    }
    
    @objc private func rowClueTapped(_ gesture: UITapGestureRecognizer) {
        guard !gameCompleted, let clue = gesture.view as? ClueLabelView else { return }
        
        // Dismiss current sum preview immediately if showing
        clue.restoreTarget()
        
        let row = clue.index
        game.autoMarkRow(row)
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        for col in 0..<game.size {
            cellViews[row][col].state = game.cellStates[row][col]
        }
        
        updateClueStates()
        checkWinCondition()
    }
    
    @objc private func rowClueLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard Settings.showCurrentSum else { return }
        guard let clue = gesture.view as? ClueLabelView else { return }
        let row = clue.index
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            clue.showCurrentSum(game.currentRowSum(row))
        case .ended, .cancelled:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                clue.restoreTarget()
            }
        default:
            break
        }
    }
    
    @objc private func colClueLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard Settings.showCurrentSum else { return }
        guard let clue = gesture.view as? ClueLabelView else { return }
        let col = clue.index
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            clue.showCurrentSum(game.currentColSum(col))
        case .ended, .cancelled:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                clue.restoreTarget()
            }
        default:
            break
        }
    }
    
    @objc private func colClueTapped(_ gesture: UITapGestureRecognizer) {
        guard !gameCompleted, let clue = gesture.view as? ClueLabelView else { return }
        
        // Dismiss current sum preview immediately if showing
        clue.restoreTarget()
        
        let col = clue.index
        game.autoMarkCol(col)
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        for row in 0..<game.size {
            cellViews[row][col].state = game.cellStates[row][col]
        }
        
        updateClueStates()
        checkWinCondition()
    }
    
    // MARK: - Toolbar Actions
    
    @objc private func undoTapped() {
        guard !gameCompleted else { return }
        if let action = game.undo() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            cellViews[action.row][action.col].state = game.cellStates[action.row][action.col]
            updateClueStates()
        }
    }
    
    @objc private func hintTapped() {
        guard !gameCompleted else { return }
        
        let alert = UIAlertController(title: "Use Hint", message: "Show the next logical deduction?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Show Hint", style: .default) { [weak self] _ in
            self?.revealHint()
        })
        present(alert, animated: true)
    }
    
    private func revealHint() {
        var hintRow: Int
        var hintCol: Int
        var explanation: String?
        
        if let deduction = game.nextLogicalDeduction() {
            hintRow = deduction.row
            hintCol = deduction.col
            explanation = deduction.reason
        } else {
            var candidates: [(Int, Int)] = []
            for row in 0..<game.size {
                for col in 0..<game.size {
                    let state = game.cellStates[row][col]
                    let shouldKeep = game.solution[row][col]
                    if state == .blank {
                        candidates.append((row, col))
                    } else if (state == .kept && !shouldKeep) || (state == .deleted && shouldKeep) {
                        candidates.append((row, col))
                    }
                }
            }
            guard let pick = candidates.randomElement() else { return }
            hintRow = pick.0
            hintCol = pick.1
        }
        
        let row = hintRow
        let col = hintCol
        
        hintsUsedThisGame += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let correctState: CellState = game.solution[row][col] ? .kept : .deleted
        let previous = game.cellStates[row][col]
        game.undoStack.append(UndoAction(row: row, col: col, previousState: previous))
        game.cellStates[row][col] = correctState
        cellViews[row][col].state = correctState
        
        let originalBorderWidth = cellViews[row][col].layer.borderWidth
        let originalBorderColor = cellViews[row][col].layer.borderColor
        cellViews[row][col].layer.borderWidth = 3
        cellViews[row][col].layer.borderColor = UIColor.systemBlue.cgColor
        UIView.animate(withDuration: 1.5) {
            self.cellViews[row][col].layer.borderWidth = originalBorderWidth
            self.cellViews[row][col].layer.borderColor = originalBorderColor
        }
        
        updateClueStates()
        checkWinCondition()
        
        if let explanation = explanation {
            let action = correctState == .kept ? "Keep" : "Delete"
            let alert = UIAlertController(
                title: "\(action) the \(game.grid[row][col])",
                message: explanation,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Got it", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func revealTapped() {
        guard !gameCompleted else { return }
        
        let alert = UIAlertController(title: "Reveal Solution", message: "Show the full solution? This will end the current game.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reveal", style: .destructive) { [weak self] _ in
            self?.revealSolution()
        })
        present(alert, animated: true)
    }
    
    private func revealSolution() {
        gameCompleted = true
        stopTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        StatsManager.shared.recordReveal()
        
        for row in 0..<game.size {
            for col in 0..<game.size {
                let correctState: CellState = game.solution[row][col] ? .kept : .deleted
                game.cellStates[row][col] = correctState
                cellViews[row][col].state = correctState
            }
        }
        
        updateClueStates()
    }
    
    @objc private func checkTapped() {
        guard !gameCompleted else { return }
        
        checksUsedThisGame += 1
        clearIncorrectHighlights()
        
        var incorrectCount = 0
        for row in 0..<game.size {
            for col in 0..<game.size {
                let state = game.cellStates[row][col]
                guard state != .blank else { continue }
                
                let shouldKeep = game.solution[row][col]
                let isCorrect = (state == .kept && shouldKeep) || (state == .deleted && !shouldKeep)
                
                if !isCorrect {
                    cellViews[row][col].isIncorrect = true
                    incorrectCount += 1
                }
            }
        }
        
        if incorrectCount > 0 {
            // Double error haptic burst to make it noticeable
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.prepare()
            heavy.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                heavy.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.clearIncorrectHighlights()
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func clearIncorrectHighlights() {
        for row in 0..<game.size {
            for col in 0..<game.size {
                cellViews[row][col].isIncorrect = false
            }
        }
    }
    
    @objc private func sizeChanged(_ sender: UISegmentedControl) {
        let newSize = sender.selectedSegmentIndex + 3
        guard newSize != currentSize else { return }
        
        let hasGuesses = !gameCompleted && game.cellStates.contains { row in row.contains { $0 != .blank } }
        
        if hasGuesses {
            let alert = UIAlertController(title: "Change Size", message: "This will abandon the current puzzle. Continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                guard let self = self else { return }
                sender.selectedSegmentIndex = self.currentSize - 3
            })
            alert.addAction(UIAlertAction(title: "Change", style: .default) { [weak self] _ in
                guard let self = self else { return }
                StatsManager.shared.recordAbandon()
                self.currentSize = newSize
                StatsManager.shared.currentSize = newSize
                self.game = SumpleteGame(size: newSize, difficulty: .easy)
                self.startNewGame()
            })
            present(alert, animated: true)
        } else {
            currentSize = newSize
            StatsManager.shared.currentSize = newSize
            game = SumpleteGame(size: newSize, difficulty: .easy)
            startNewGame()
        }
    }
    
    @objc private func newGameTapped() {
        if !gameCompleted {
            let alert = UIAlertController(title: "New Puzzle", message: "Abandon current puzzle and start a new one?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "New Puzzle", style: .default) { [weak self] _ in
                StatsManager.shared.recordAbandon()
                self?.startNewGame()
            })
            present(alert, animated: true)
        } else {
            startNewGame()
        }
    }
    
    private func startNewGame() {
        gameCompleted = false
        hintsUsedThisGame = 0
        checksUsedThisGame = 0
        game.newGame()
        buildGrid()
        updateClueStates()
        elapsedSeconds = 0
        updateTimerLabel()
        stopTimer()
        startTimer()
        
        // Clear any saved game since we're starting fresh
        SumpleteGame.clearSave()
        UserDefaults.standard.removeObject(forKey: GameViewController.metaKey)
    }
    
    // MARK: - Clue State Updates
    
    private func updateClueStates() {
        for row in 0..<game.size {
            rowClueViews[row].sumsMatch = game.rowSumMatches(row)
            rowClueViews[row].isSolved = game.isRowSolved(row)
        }
        for col in 0..<game.size {
            colClueViews[col].sumsMatch = game.colSumMatches(col)
            colClueViews[col].isSolved = game.isColSolved(col)
        }
    }
    
    // MARK: - Win Detection
    
    private func checkWinCondition() {
        guard game.isSolved else { return }
        
        gameCompleted = true
        stopTimer()
        
        // Record stats
        StatsManager.shared.recordWin(
            time: elapsedSeconds,
            hintsUsed: hintsUsedThisGame,
            checksUsed: checksUsedThisGame
        )
        
        // Animate celebration
        UIView.animate(withDuration: 0.3) {
            for row in self.cellViews {
                for cell in row {
                    if cell.state == .kept {
                        cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showWinCelebration()
        }
    }
    
    private func showWinCelebration() {
        let celebration = WinCelebrationView()
        celebration.frame = view.bounds
        celebration.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        celebration.configure(time: elapsedSeconds, hintsUsed: hintsUsedThisGame, checksUsed: checksUsedThisGame)
        
        // Prepare haptic engines early so they're ready when animateIn fires
        celebration.prepareHaptics()
        
        celebration.onNewPuzzle = { [weak self] in
            self?.startNewGame()
        }
        celebration.onDismiss = {}
        
        view.addSubview(celebration)
        celebration.animateIn()

        // Once the celebration has had a moment, ask for a rating if it's due.
        if ReviewPrompter.recordSolve() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let scene = self?.view.window?.windowScene else { return }
                AppStore.requestReview(in: scene)
            }
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.updateTimerLabel()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimerLabel() {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Save / Restore
    
    private struct GameMeta: Codable {
        let elapsedSeconds: Int
        let hintsUsed: Int
        let checksUsed: Int
        let gameCompleted: Bool
    }
    
    private static let metaKey = "savedGameMeta"
    
    /// Save the current game and metadata so it can be restored later
    func saveGame() {
        // Don't save if the game is already completed
        guard !gameCompleted else {
            SumpleteGame.clearSave()
            UserDefaults.standard.removeObject(forKey: GameViewController.metaKey)
            return
        }
        
        game.save()
        let meta = GameMeta(
            elapsedSeconds: elapsedSeconds,
            hintsUsed: hintsUsedThisGame,
            checksUsed: checksUsedThisGame,
            gameCompleted: gameCompleted
        )
        if let encoded = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(encoded, forKey: GameViewController.metaKey)
        }
    }
    
    private static func restoreMeta() -> GameMeta? {
        guard let data = UserDefaults.standard.data(forKey: metaKey),
              let meta = try? JSONDecoder().decode(GameMeta.self, from: data) else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: metaKey)
        return meta
    }
}

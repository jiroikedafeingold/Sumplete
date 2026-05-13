//
//  HowToPlayViewController.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import UIKit

class HowToPlayViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // Max width keeps text readable on iPad
        let maxContentWidth: CGFloat = 500
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: maxContentWidth),
        ])
        
        // On iPhone, fill the width; on iPad, cap at max
        let fillWidth = contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        fillWidth.priority = .defaultHigh
        fillWidth.isActive = true
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "How to Play"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        
        // --- Goal ---
        addSection(title: "Goal", body: "Delete numbers from the grid so that the remaining numbers in each row and column add up to the target values.")
        
        // --- Cell States with graphic ---
        addSection(title: "Cell States", body: "Tap a cell to cycle through three states:")
        contentStack.addArrangedSubview(makeCellStatesExample())
        
        // --- Example Grid ---
        addSection(title: "Example", body: "Here is a solved 3x3 puzzle. The kept numbers (green circles) in each row and column add up to the targets on the right and bottom:")
        contentStack.addArrangedSubview(makeSolvedGridExample())
        
        // --- Target Totals ---
        addSection(title: "Target Totals", body: "The numbers on the right are row targets. The numbers on the bottom are column targets.\n\nWhen kept cells add up to the target, the label turns bold. When fully solved, it turns green.\n\nTap a target to auto-fill remaining cells if only one possibility remains. This is especially useful for 0 targets — every cell in that row or column should be deleted.")
        
        // --- Long Press ---
        addSection(title: "Long Press", body: "Long press on a target total to temporarily see the current sum of kept cells in that row or column. It shows in blue and stays visible for a few seconds after release.")
        
        // --- Toolbar ---
        addSection(title: "Toolbar", body: nil)
        contentStack.addArrangedSubview(makeToolbarDescription())
        
        // --- Tips ---
        addSection(title: "Tips", body: "Start with rows or columns where the target is 0 (delete everything) or very high (keep most cells). Use the long-press feature to track your progress toward each target. If you're stuck, use Check to see if any guesses are wrong before using a Hint.")
    }
    
    // MARK: - Section Helper
    
    private func addSection(title: String, body: String?) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        stack.addArrangedSubview(titleLabel)
        
        if let body = body {
            let bodyLabel = UILabel()
            bodyLabel.text = body
            bodyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            bodyLabel.textColor = .secondaryLabel
            bodyLabel.numberOfLines = 0
            stack.addArrangedSubview(bodyLabel)
        }
        
        contentStack.addArrangedSubview(stack)
    }
    
    // MARK: - Cell States Graphic
    
    private func makeCellStatesExample() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center
        container.distribution = .fillEqually
        
        container.addArrangedSubview(makeCellExample(number: 5, state: .blank, label: "Blank\n(undecided)"))
        container.addArrangedSubview(makeCellExample(number: 3, state: .deleted, label: "Deleted\n(removed)"))
        container.addArrangedSubview(makeCellExample(number: 7, state: .kept, label: "Kept\n(counts)"))
        
        return container
    }
    
    private func makeCellExample(number: Int, state: CellState, label: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        
        let cell = UIView()
        cell.layer.cornerRadius = 6
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.translatesAutoresizingMaskIntoConstraints = false
        
        let numLabel = UILabel()
        numLabel.text = "\(number)"
        numLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        numLabel.textAlignment = .center
        numLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(numLabel)
        
        let overlayImage = UIImageView()
        overlayImage.contentMode = .scaleAspectFit
        overlayImage.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(overlayImage)
        
        switch state {
        case .blank:
            cell.backgroundColor = .systemGray6
            numLabel.textColor = .label
            overlayImage.isHidden = true
        case .deleted:
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            numLabel.textColor = UIColor.systemRed.withAlphaComponent(0.4)
            overlayImage.image = UIImage(systemName: "xmark")
            overlayImage.tintColor = UIColor.systemRed.withAlphaComponent(0.8)
        case .kept:
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            numLabel.textColor = .label
            overlayImage.image = UIImage(systemName: "circle")
            overlayImage.tintColor = UIColor.systemGreen.withAlphaComponent(0.8)
        }
        
        NSLayoutConstraint.activate([
            cell.widthAnchor.constraint(equalToConstant: 50),
            cell.heightAnchor.constraint(equalToConstant: 50),
            numLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            numLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            overlayImage.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            overlayImage.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            overlayImage.widthAnchor.constraint(equalToConstant: 36),
            overlayImage.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        let descLabel = UILabel()
        descLabel.text = label
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        stack.addArrangedSubview(cell)
        stack.addArrangedSubview(descLabel)
        
        return stack
    }
    
    // MARK: - Solved Grid Example
    
    private func makeSolvedGridExample() -> UIView {
        // A simple 3x3 example puzzle:
        // Grid:     Solution:      Row targets:
        // 4 2 8     keep del keep  -> 12 (4+8)
        // 1 6 3     del keep del   -> 6
        // 5 9 7     keep del keep  -> 12 (5+7)
        // Col:      9    6    15
        //           (4+5)(6)  (8+7)
        
        let gridValues = [[4, 2, 8], [1, 6, 3], [5, 9, 7]]
        let solution: [[Bool]] = [[true, false, true], [false, true, false], [true, false, true]]
        let rowTargets = [12, 6, 12]
        let colTargets = [9, 6, 15]
        
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 2
        outerStack.alignment = .center
        
        let gridAndClues = UIStackView()
        gridAndClues.axis = .vertical
        gridAndClues.spacing = 2
        gridAndClues.alignment = .center
        
        let cellSize: CGFloat = 44
        let clueSize: CGFloat = 36
        let spacing: CGFloat = 2
        
        // Game rows + row clues
        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = spacing
            rowStack.alignment = .fill
            
            for col in 0..<3 {
                let cell = makeExampleCell(
                    number: gridValues[row][col],
                    kept: solution[row][col],
                    size: cellSize
                )
                rowStack.addArrangedSubview(cell)
            }
            
            // Separator + row clue
            let sep = UIView()
            sep.backgroundColor = .systemGray3
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
            rowStack.addArrangedSubview(sep)
            
            let clue = makeClueLabel(value: rowTargets[row], size: CGSize(width: clueSize, height: cellSize), solved: true)
            rowStack.addArrangedSubview(clue)
            
            gridAndClues.addArrangedSubview(rowStack)
        }
        
        // Horizontal separator + column clues
        let hSep = UIView()
        hSep.backgroundColor = .systemGray3
        hSep.translatesAutoresizingMaskIntoConstraints = false
        hSep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        hSep.widthAnchor.constraint(equalToConstant: cellSize * 3 + spacing * 2 + 1 + clueSize).isActive = true
        gridAndClues.addArrangedSubview(hSep)
        
        let colRow = UIStackView()
        colRow.axis = .horizontal
        colRow.spacing = spacing
        colRow.alignment = .fill
        
        for col in 0..<3 {
            let clue = makeClueLabel(value: colTargets[col], size: CGSize(width: cellSize, height: clueSize), solved: true)
            colRow.addArrangedSubview(clue)
        }
        
        // Spacer for alignment with the separator + clue column
        let corner = UIView()
        corner.translatesAutoresizingMaskIntoConstraints = false
        corner.widthAnchor.constraint(equalToConstant: 1 + clueSize).isActive = true
        colRow.addArrangedSubview(corner)
        
        gridAndClues.addArrangedSubview(colRow)
        outerStack.addArrangedSubview(gridAndClues)
        
        return outerStack
    }
    
    private func makeExampleCell(number: Int, kept: Bool, size: CGFloat) -> UIView {
        let cell = UIView()
        cell.layer.cornerRadius = 4
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.translatesAutoresizingMaskIntoConstraints = false
        
        let numLabel = UILabel()
        numLabel.text = "\(number)"
        numLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        numLabel.textAlignment = .center
        numLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(numLabel)
        
        let overlay = UIImageView()
        overlay.contentMode = .scaleAspectFit
        overlay.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(overlay)
        
        if kept {
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            numLabel.textColor = .label
            overlay.image = UIImage(systemName: "circle")
            overlay.tintColor = UIColor.systemGreen.withAlphaComponent(0.8)
        } else {
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            numLabel.textColor = UIColor.systemRed.withAlphaComponent(0.4)
            overlay.image = UIImage(systemName: "xmark")
            overlay.tintColor = UIColor.systemRed.withAlphaComponent(0.8)
        }
        
        NSLayoutConstraint.activate([
            cell.widthAnchor.constraint(equalToConstant: size),
            cell.heightAnchor.constraint(equalToConstant: size),
            numLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            numLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            overlay.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            overlay.widthAnchor.constraint(equalToConstant: size * 0.7),
            overlay.heightAnchor.constraint(equalToConstant: size * 0.7),
        ])
        
        return cell
    }
    
    private func makeClueLabel(value: Int, size: CGSize, solved: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "\(value)"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        label.textColor = solved ? .systemGreen : .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: size.width),
            container.heightAnchor.constraint(equalToConstant: size.height),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        
        return container
    }
    
    // MARK: - Toolbar Description
    
    private func makeToolbarDescription() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        
        let items: [(String, String, String)] = [
            ("checkmark.circle", "Check", "Highlights incorrect guesses in orange for a few seconds"),
            ("lightbulb.fill", "Hint", "Shows the next logical deduction — the same move you'd find by reasoning through the puzzle"),
            ("eye.fill", "Reveal", "Shows the full solution (ends the game)"),
            ("arrow.uturn.backward", "Undo", "Reverts the last move"),
        ]
        
        for (icon, title, desc) in items {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.alignment = .center
            
            let imageView = UIImageView(image: UIImage(systemName: icon))
            imageView.tintColor = .label
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 22).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 22).isActive = true
            
            let textStack = UIStackView()
            textStack.axis = .vertical
            textStack.spacing = 1
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            titleLabel.textColor = .label
            
            let descLabel = UILabel()
            descLabel.text = desc
            descLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            descLabel.textColor = .secondaryLabel
            descLabel.numberOfLines = 0
            
            textStack.addArrangedSubview(titleLabel)
            textStack.addArrangedSubview(descLabel)
            
            row.addArrangedSubview(imageView)
            row.addArrangedSubview(textStack)
            
            stack.addArrangedSubview(row)
        }
        
        return stack
    }
}

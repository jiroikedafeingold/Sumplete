//
//  StatsViewController.swift
//  Sumplete
//
//  Created by Jiro on 4/4/26.
//

import UIKit

class StatsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let sizeSelector = UISegmentedControl()
    private var selectedSize: Int = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStats()
    }
    
    private func setupUI() {
        // Size selector at top
        for (i, size) in StatsManager.allSizes.enumerated() {
            sizeSelector.insertSegment(withTitle: "\(size)x\(size)", at: i, animated: false)
        }
        sizeSelector.selectedSegmentIndex = selectedSize - 3
        sizeSelector.addTarget(self, action: #selector(sizeChanged(_:)), for: .valueChanged)
        sizeSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sizeSelector)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // Max width keeps content readable on iPad
        let maxContentWidth: CGFloat = 500
        
        NSLayoutConstraint.activate([
            sizeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            sizeSelector.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sizeSelector.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            sizeSelector.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            sizeSelector.widthAnchor.constraint(lessThanOrEqualToConstant: maxContentWidth),
            
            scrollView.topAnchor.constraint(equalTo: sizeSelector.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: maxContentWidth),
        ])
        
        // On iPhone, fill the width; on iPad, cap at max
        let fillWidth = contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        fillWidth.priority = .defaultHigh
        fillWidth.isActive = true
    }
    
    @objc private func sizeChanged(_ sender: UISegmentedControl) {
        selectedSize = sender.selectedSegmentIndex + 3
        refreshStats()
    }
    
    private func refreshStats() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let stats = StatsManager.shared
        let size = selectedSize
        
        // Temporarily set currentSize for reading
        let previousSize = stats.currentSize
        stats.currentSize = size
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "\(size)x\(size) Statistics"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(20, after: titleLabel)
        
        // Games
        let topRow = makeStatRow([
            ("Games Played", "\(stats.gamesPlayed)"),
            ("Games Won", "\(stats.gamesWon)"),
            ("Win Rate", stats.gamesPlayed > 0 ? "\(Int(stats.winRate * 100))%" : "-"),
        ])
        contentStack.addArrangedSubview(topRow)
        contentStack.setCustomSpacing(12, after: topRow)
        
        // Time
        let timeRow = makeStatRow([
            ("Best Time", stats.bestTime > 0 ? StatsManager.formatTime(stats.bestTime) : "-"),
            ("Avg Time", stats.gamesWon > 0 ? StatsManager.formatTime(stats.averageTime) : "-"),
            ("Total Time", StatsManager.formatTime(stats.totalTimePlayed)),
        ])
        contentStack.addArrangedSubview(timeRow)
        contentStack.setCustomSpacing(12, after: timeRow)
        
        // Streaks
        let streakRow = makeStatRow([
            ("Current Streak", "\(stats.currentStreak)"),
            ("Best Streak", "\(stats.bestStreak)"),
        ])
        contentStack.addArrangedSubview(streakRow)
        contentStack.setCustomSpacing(12, after: streakRow)
        
        // Hints & Checks
        let hintRow = makeStatRow([
            ("Avg Hints", stats.gamesWon > 0 ? String(format: "%.1f", stats.averageHintsPerGame) : "-"),
            ("No-Hint Wins", "\(stats.gamesWonWithoutHints)"),
            ("Total Checks", "\(stats.totalChecksUsed)"),
        ])
        contentStack.addArrangedSubview(hintRow)
        contentStack.setCustomSpacing(12, after: hintRow)
        
        // Reveals & Abandons
        let abandoned = max(0, stats.gamesPlayed - stats.gamesWon - stats.totalReveals)
        let otherRow = makeStatRow([
            ("Reveals", "\(stats.totalReveals)"),
            ("Abandoned", "\(abandoned)"),
        ])
        contentStack.addArrangedSubview(otherRow)
        contentStack.setCustomSpacing(28, after: otherRow)
        
        // Restore previous size
        stats.currentSize = previousSize
        
        // Reset button
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset All Stats", for: .normal)
        resetButton.setTitleColor(.systemRed, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(resetButton)
    }
    
    private func makeStatRow(_ items: [(String, String)]) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .top
        row.distribution = .fillEqually
        
        for (label, value) in items {
            let card = makeStatCard(label: label, value: value)
            row.addArrangedSubview(card)
        }
        
        return row
    }
    
    private func makeStatCard(label: String, value: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
        ])
        
        return card
    }
    
    @objc private func resetTapped() {
        let alert = UIAlertController(
            title: "Reset Statistics",
            message: "This will permanently delete stats for all board sizes. Are you sure?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            StatsManager.shared.resetAll()
            self?.refreshStats()
        })
        present(alert, animated: true)
    }
}

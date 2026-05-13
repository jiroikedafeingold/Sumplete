//
//  ClueLabelView.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import UIKit

class ClueLabelView: UIView {
    
    private let label = UILabel()
    
    var target: Int = 0 {
        didSet { label.text = "\(target)" }
    }
    
    /// The current sum matches the target (bold the label)
    var sumsMatch: Bool = false {
        didSet { updateAppearance() }
    }
    
    /// Fully solved (all cells decided AND sum matches)
    var isSolved: Bool = false {
        didSet {
            updateAppearance()
            if isSolved && !oldValue {
                animateSolved()
            }
        }
    }
    
    /// Whether this is a row clue (right side) or column clue (bottom)
    var isRowClue: Bool = true
    var index: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.systemGray5
        layer.cornerRadius = 4
        
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        isUserInteractionEnabled = true
    }
    
    private var isShowingCurrentSum = false
    
    /// Temporarily show the current sum instead of the target
    func showCurrentSum(_ sum: Int) {
        isShowingCurrentSum = true
        label.text = "\(sum)"
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        label.textColor = UIColor.systemBlue
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold)
    }
    
    /// Restore the target display
    func restoreTarget() {
        isShowingCurrentSum = false
        label.text = "\(target)"
        updateAppearance()
    }
    
    private func animateSolved() {
        // Scale up then back with a spring
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut]) {
            self.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8) {
                self.transform = .identity
            }
        }
        
        // Brief bright green flash, then settle to solved color
        let solvedColor = UIColor.systemGreen.withAlphaComponent(0.25)
        let flashColor = UIColor.systemGreen.withAlphaComponent(0.6)
        backgroundColor = flashColor
        UIView.animate(withDuration: 0.5, delay: 0.1, options: [.curveEaseOut]) {
            self.backgroundColor = solvedColor
        }
    }
    
    private func updateAppearance() {
        guard !isShowingCurrentSum else { return }
        
        if isSolved {
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.25)
            label.textColor = UIColor.systemGreen
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .black)
        } else if sumsMatch {
            backgroundColor = UIColor.systemGray5
            label.textColor = .label
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .black)
        } else {
            backgroundColor = UIColor.systemGray5
            label.textColor = .secondaryLabel
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        }
    }
}

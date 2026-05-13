//
//  GridCellView.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import UIKit

class GridCellView: UIView {
    
    private let numberLabel = UILabel()
    private let overlayImageView = UIImageView()
    
    var number: Int = 0 {
        didSet { numberLabel.text = "\(number)" }
    }
    
    var state: CellState = .blank {
        didSet { updateAppearance() }
    }
    
    var isIncorrect: Bool = false {
        didSet { updateAppearance() }
    }
    
    var row: Int = 0
    var col: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 4
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.systemGray4.cgColor
        
        numberLabel.textAlignment = .center
        numberLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        numberLabel.textColor = .label
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)
        
        overlayImageView.contentMode = .scaleAspectFit
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.isHidden = true
        addSubview(overlayImageView)
        
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlayImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlayImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),
            overlayImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.75),
        ])
        
        isUserInteractionEnabled = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        // Reset incorrect border
        if isIncorrect {
            layer.borderWidth = 2.5
            layer.borderColor = UIColor.systemOrange.cgColor
        } else {
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.systemGray4.cgColor
        }
        
        switch state {
        case .blank:
            backgroundColor = UIColor.systemGray6
            numberLabel.textColor = .label
            numberLabel.alpha = 1.0
            overlayImageView.isHidden = true
            
        case .deleted:
            backgroundColor = isIncorrect
                ? UIColor.systemOrange.withAlphaComponent(0.15)
                : UIColor.systemRed.withAlphaComponent(0.12)
            numberLabel.textColor = UIColor.systemRed.withAlphaComponent(0.4)
            numberLabel.alpha = 1.0
            overlayImageView.isHidden = false
            overlayImageView.image = UIImage(systemName: "xmark")
            overlayImageView.tintColor = UIColor.systemRed.withAlphaComponent(0.8)
            
        case .kept:
            backgroundColor = isIncorrect
                ? UIColor.systemOrange.withAlphaComponent(0.15)
                : UIColor.systemGreen.withAlphaComponent(0.12)
            numberLabel.textColor = .label
            numberLabel.alpha = 1.0
            overlayImageView.isHidden = false
            overlayImageView.image = UIImage(systemName: "circle")
            overlayImageView.tintColor = UIColor.systemGreen.withAlphaComponent(0.8)
        }
    }
}

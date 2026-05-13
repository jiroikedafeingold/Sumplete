//
//  WinCelebrationView.swift
//  Sumplete
//
//  Created by Jiro on 4/4/26.
//

import UIKit

class WinCelebrationView: UIView {
    
    private let blurView = UIVisualEffectView(effect: nil)
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let statsStack = UIStackView()
    private let newPuzzleButton = UIButton()
    private let dismissButton = UIButton()
    private var confettiLayers: [CALayer] = []
    
    // Pre-create haptic generators so they can be prepared early
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let successHaptic = UINotificationFeedbackGenerator()
    
    var onNewPuzzle: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Blur background
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        // Content card
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 20
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 20
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        addSubview(contentView)
        
        // Title
        titleLabel.text = "Puzzle Solved!"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Time
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        // Stats
        statsStack.axis = .vertical
        statsStack.spacing = 8
        statsStack.alignment = .fill
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsStack)
        
        // New Puzzle button
        var npConfig = UIButton.Configuration.filled()
        npConfig.title = "New Puzzle"
        npConfig.baseBackgroundColor = .systemGreen
        npConfig.baseForegroundColor = .white
        npConfig.cornerStyle = .large
        npConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            return out
        }
        npConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 40, bottom: 14, trailing: 40)
        newPuzzleButton.configuration = npConfig
        newPuzzleButton.translatesAutoresizingMaskIntoConstraints = false
        newPuzzleButton.addTarget(self, action: #selector(newPuzzleTapped), for: .touchUpInside)
        contentView.addSubview(newPuzzleButton)
        
        // Dismiss button
        dismissButton.setTitle("Continue", for: .normal)
        dismissButton.setTitleColor(.secondaryLabel, for: .normal)
        dismissButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        contentView.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            statsStack.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            newPuzzleButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 24),
            newPuzzleButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            dismissButton.topAnchor.constraint(equalTo: newPuzzleButton.bottomAnchor, constant: 10),
            dismissButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }
    
    func configure(time: Int, hintsUsed: Int, checksUsed: Int) {
        let stats = StatsManager.shared
        timeLabel.text = StatsManager.formatTime(time)
        
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // This game stats
        var thisGameItems: [(String, String)] = []
        if hintsUsed > 0 { thisGameItems.append(("Hints Used", "\(hintsUsed)")) }
        if checksUsed > 0 { thisGameItems.append(("Checks Used", "\(checksUsed)")) }
        if hintsUsed == 0 { thisGameItems.append(("No Hints!", "")) }
        
        if !thisGameItems.isEmpty {
            for (label, value) in thisGameItems {
                statsStack.addArrangedSubview(makeStatLine(label: label, value: value))
            }
            statsStack.addArrangedSubview(makeSeparator())
        }
        
        // Overall stats
        statsStack.addArrangedSubview(makeStatLine(label: "Games Won", value: "\(stats.gamesWon)"))
        statsStack.addArrangedSubview(makeStatLine(label: "Win Rate", value: "\(Int(stats.winRate * 100))%"))
        statsStack.addArrangedSubview(makeStatLine(label: "Best Time", value: StatsManager.formatTime(stats.bestTime)))
        statsStack.addArrangedSubview(makeStatLine(label: "Avg Time", value: StatsManager.formatTime(stats.averageTime)))
        statsStack.addArrangedSubview(makeStatLine(label: "Streak", value: "\(stats.currentStreak)"))
        if stats.bestStreak > stats.currentStreak {
            statsStack.addArrangedSubview(makeStatLine(label: "Best Streak", value: "\(stats.bestStreak)"))
        }
    }
    
    private func makeStatLine(label: String, value: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        labelView.textColor = .secondaryLabel
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        valueView.textColor = .label
        valueView.textAlignment = .right
        
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(valueView)
        
        return row
    }
    
    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return sep
    }
    
    // MARK: - Haptics
    
    /// Call this before animateIn() so the Taptic Engine has time to spin up
    func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        successHaptic.prepare()
    }
    
    // MARK: - Animation
    
    func animateIn() {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
            self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
            self.contentView.alpha = 1
            self.contentView.transform = .identity
        }
        
        // Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startConfetti()
        }
        
        // Fun haptic burst — escalating impacts then success
        playWinHaptics()
    }
    
    private func playWinHaptics() {
        // Rapid ascending burst with initial delay to ensure engine is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.lightHaptic.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { [weak self] in self?.lightHaptic.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) { [weak self] in self?.mediumHaptic.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.29) { [weak self] in self?.mediumHaptic.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.37) { [weak self] in self?.heavyHaptic.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in self?.heavyHaptic.impactOccurred() }
        // Finish with a success notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) { [weak self] in self?.successHaptic.notificationOccurred(.success) }
    }
    
    func animateOut(completion: @escaping () -> Void) {
        stopConfetti()
        UIView.animate(withDuration: 0.3, animations: {
            self.blurView.effect = nil
            self.contentView.alpha = 0
            self.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
            completion()
        }
    }
    
    // MARK: - Confetti
    
    private func startConfetti() {
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemOrange, .systemPurple, .systemPink]
        
        for _ in 0..<60 {
            let confetti = CALayer()
            let size: CGFloat = CGFloat.random(in: 6...12)
            confetti.frame = CGRect(
                x: CGFloat.random(in: 0...bounds.width),
                y: -20,
                width: size,
                height: size
            )
            confetti.backgroundColor = colors.randomElement()!.cgColor
            confetti.cornerRadius = Bool.random() ? size / 2 : 0
            confetti.opacity = 0
            layer.addSublayer(confetti)
            confettiLayers.append(confetti)
            
            // Fall animation
            let fall = CABasicAnimation(keyPath: "position.y")
            fall.fromValue = CGFloat.random(in: -40...0)
            fall.toValue = bounds.height + 20
            fall.duration = Double.random(in: 2.0...4.0)
            fall.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.0)
            fall.fillMode = .forwards
            fall.isRemovedOnCompletion = false
            
            // Horizontal drift
            let drift = CABasicAnimation(keyPath: "position.x")
            drift.fromValue = confetti.position.x
            drift.toValue = confetti.position.x + CGFloat.random(in: -60...60)
            drift.duration = fall.duration
            drift.beginTime = fall.beginTime
            drift.fillMode = .forwards
            drift.isRemovedOnCompletion = false
            
            // Spin
            let spin = CABasicAnimation(keyPath: "transform.rotation.z")
            spin.fromValue = 0
            spin.toValue = CGFloat.random(in: -6...6)
            spin.duration = fall.duration
            spin.beginTime = fall.beginTime
            spin.fillMode = .forwards
            spin.isRemovedOnCompletion = false
            
            // Fade in
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = Float.random(in: 0.7...1.0)
            fadeIn.duration = 0.3
            fadeIn.beginTime = fall.beginTime
            fadeIn.fillMode = .forwards
            fadeIn.isRemovedOnCompletion = false
            
            confetti.add(fall, forKey: "fall")
            confetti.add(drift, forKey: "drift")
            confetti.add(spin, forKey: "spin")
            confetti.add(fadeIn, forKey: "fadeIn")
        }
    }
    
    private func stopConfetti() {
        for layer in confettiLayers {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        confettiLayers.removeAll()
    }
    
    // MARK: - Actions
    
    @objc private func newPuzzleTapped() {
        animateOut { [weak self] in
            self?.onNewPuzzle?()
        }
    }
    
    @objc private func dismissTapped() {
        animateOut { [weak self] in
            self?.onDismiss?()
        }
    }
}

//
//  SettingsViewController.swift
//  Sumplete
//
//  Created by Jiro on 4/17/26.
//

import UIKit

// MARK: - Settings Keys

enum SettingsKey {
    static let showCurrentSum = "settings_showCurrentSum"
    static let guaranteeLogicSolvable = "settings_guaranteeLogicSolvable"
}

// MARK: - Settings Manager

struct Settings {
    static var showCurrentSum: Bool {
        get {
            // Default to true if never set
            if UserDefaults.standard.object(forKey: SettingsKey.showCurrentSum) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: SettingsKey.showCurrentSum)
        }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.showCurrentSum) }
    }
    
    static var guaranteeLogicSolvable: Bool {
        get {
            // Default to true if never set
            if UserDefaults.standard.object(forKey: SettingsKey.guaranteeLogicSolvable) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: SettingsKey.guaranteeLogicSolvable)
        }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.guaranteeLogicSolvable) }
    }
}

// MARK: - Settings View Controller

class SettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let showCurrentSumToggle = UISwitch()
    private let logicSolvableToggle = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showCurrentSumToggle.isOn = Settings.showCurrentSum
        logicSolvableToggle.isOn = Settings.guaranteeLogicSolvable
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
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
        
        let fillWidth = contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        fillWidth.priority = .defaultHigh
        fillWidth.isActive = true
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        
        // --- Gameplay Settings ---
        addSectionHeader("Gameplay")
        
        showCurrentSumToggle.isOn = Settings.showCurrentSum
        showCurrentSumToggle.addTarget(self, action: #selector(showCurrentSumChanged), for: .valueChanged)
        addToggleRow(
            title: "Show Current Sum",
            description: "Long press a target total to see the current sum of kept cells in that row or column.",
            toggle: showCurrentSumToggle
        )
        
        logicSolvableToggle.isOn = Settings.guaranteeLogicSolvable
        logicSolvableToggle.addTarget(self, action: #selector(logicSolvableChanged), for: .valueChanged)
        addToggleRow(
            title: "Guarantee Logic Solvable",
            description: "Every puzzle can be solved through deduction alone, without guessing. Turning this off allows harder puzzles that may require trial and error.",
            toggle: logicSolvableToggle
        )
        
        // --- About / Attribution ---
        addSectionHeader("About")
        addAttribution()
    }
    
    // MARK: - Toggle Actions
    
    @objc private func showCurrentSumChanged(_ sender: UISwitch) {
        Settings.showCurrentSum = sender.isOn
    }
    
    @objc private func logicSolvableChanged(_ sender: UISwitch) {
        Settings.guaranteeLogicSolvable = sender.isOn
    }
    
    // MARK: - UI Helpers
    
    private func addSectionHeader(_ title: String) {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.letterSpacing = 1.0
        contentStack.addArrangedSubview(label)
        contentStack.setCustomSpacing(8, after: label)
    }
    
    private func addToggleRow(title: String, description: String, toggle: UISwitch) {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(descLabel)
        
        hStack.addArrangedSubview(textStack)
        hStack.addArrangedSubview(toggle)
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        
        contentStack.addArrangedSubview(card)
    }
    
    private func addAttribution() {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        
        let headingLabel = UILabel()
        headingLabel.text = "Inspired by Sumplete"
        headingLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        headingLabel.textColor = .label
        stack.addArrangedSubview(headingLabel)
        
        let bodyLabel = UILabel()
        bodyLabel.text = "This app is inspired by Sumplete, the original number puzzle game created by Daniel Tait. The original game is available at sumplete.com and offers daily puzzles along with a variety of grid sizes and difficulty levels.\n\nAll credit for the Sumplete concept and game design goes to Daniel Tait. This app is an independent implementation and is not affiliated with or endorsed by sumplete.com."
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        stack.addArrangedSubview(bodyLabel)
        
        let linkButton = UIButton(type: .system)
        linkButton.setTitle("Visit sumplete.com", for: .normal)
        linkButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        linkButton.contentHorizontalAlignment = .leading
        linkButton.addTarget(self, action: #selector(openSumpleteWebsite), for: .touchUpInside)
        stack.addArrangedSubview(linkButton)
        
        contentStack.addArrangedSubview(card)
    }
    
    @objc private func openSumpleteWebsite() {
        if let url = URL(string: "https://sumplete.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UILabel Letter Spacing Extension

private extension UILabel {
    var letterSpacing: CGFloat {
        get { return 0 }
        set {
            guard let text = self.text else { return }
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(.kern, value: newValue, range: NSRange(location: 0, length: text.count))
            self.attributedText = attributedString
        }
    }
}

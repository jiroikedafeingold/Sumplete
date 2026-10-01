//
//  ReviewPrompter.swift
//  Sumplete
//

import Foundation

/// Decides when to ask for an App Store rating: after the player's 3rd solved puzzle,
/// then again at most once per app version and no sooner than 10 solves after the last
/// ask. (StoreKit itself further caps the prompt at three showings a year.) Kept apart
/// from `StatsManager` so resetting stats doesn't re-trigger it.
enum ReviewPrompter {
    private static let solvesKey = "review.solves"
    private static let lastSolvesKey = "review.lastPromptSolves"
    private static let lastVersionKey = "review.lastPromptVersion"

    /// Records a solve and returns true if now is a good moment to ask for a review.
    static func recordSolve() -> Bool {
        let defaults = UserDefaults.standard
        let solves = defaults.integer(forKey: solvesKey) + 1
        defaults.set(solves, forKey: solvesKey)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastSolves = defaults.integer(forKey: lastSolvesKey)
        let neverAsked = lastSolves == 0
        guard solves >= 3,
              neverAsked || (solves - lastSolves >= 10 && defaults.string(forKey: lastVersionKey) != version)
        else { return false }

        defaults.set(solves, forKey: lastSolvesKey)
        defaults.set(version, forKey: lastVersionKey)
        return true
    }
}

//
//  StatsManager.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import Foundation

class StatsManager {
    
    static let shared = StatsManager()
    
    private let defaults = UserDefaults.standard
    
    /// The board size whose stats are currently active.
    /// Set this before recording or reading stats.
    var currentSize: Int = 9
    
    static let allSizes = Array(3...9)
    
    // MARK: - Key Generation
    
    private func key(_ base: String) -> String {
        return "stats_\(currentSize)x\(currentSize)_\(base)"
    }
    
    private func key(_ base: String, size: Int) -> String {
        return "stats_\(size)x\(size)_\(base)"
    }
    
    // MARK: - Properties (use currentSize)
    
    var gamesPlayed: Int {
        get { defaults.integer(forKey: key("gamesPlayed")) }
        set { defaults.set(newValue, forKey: key("gamesPlayed")) }
    }
    
    var gamesWon: Int {
        get { defaults.integer(forKey: key("gamesWon")) }
        set { defaults.set(newValue, forKey: key("gamesWon")) }
    }
    
    var totalTimePlayed: Int {
        get { defaults.integer(forKey: key("totalTimePlayed")) }
        set { defaults.set(newValue, forKey: key("totalTimePlayed")) }
    }
    
    var totalHintsUsed: Int {
        get { defaults.integer(forKey: key("totalHintsUsed")) }
        set { defaults.set(newValue, forKey: key("totalHintsUsed")) }
    }
    
    var totalChecksUsed: Int {
        get { defaults.integer(forKey: key("totalChecksUsed")) }
        set { defaults.set(newValue, forKey: key("totalChecksUsed")) }
    }
    
    var totalReveals: Int {
        get { defaults.integer(forKey: key("totalReveals")) }
        set { defaults.set(newValue, forKey: key("totalReveals")) }
    }
    
    var bestTime: Int {
        get { defaults.integer(forKey: key("bestTime")) }
        set { defaults.set(newValue, forKey: key("bestTime")) }
    }
    
    var currentStreak: Int {
        get { defaults.integer(forKey: key("currentStreak")) }
        set { defaults.set(newValue, forKey: key("currentStreak")) }
    }
    
    var bestStreak: Int {
        get { defaults.integer(forKey: key("bestStreak")) }
        set { defaults.set(newValue, forKey: key("bestStreak")) }
    }
    
    var gamesWonWithoutHints: Int {
        get { defaults.integer(forKey: key("gamesWonWithoutHints")) }
        set { defaults.set(newValue, forKey: key("gamesWonWithoutHints")) }
    }
    
    // MARK: - Computed
    
    var averageTime: Int {
        guard gamesWon > 0 else { return 0 }
        return totalTimePlayed / gamesWon
    }
    
    var averageHintsPerGame: Double {
        guard gamesWon > 0 else { return 0 }
        return Double(totalHintsUsed) / Double(gamesWon)
    }
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
    
    // MARK: - Size-specific accessors (for StatsViewController)
    
    func gamesPlayed(forSize size: Int) -> Int {
        defaults.integer(forKey: key("gamesPlayed", size: size))
    }
    
    func gamesWon(forSize size: Int) -> Int {
        defaults.integer(forKey: key("gamesWon", size: size))
    }
    
    func bestTime(forSize size: Int) -> Int {
        defaults.integer(forKey: key("bestTime", size: size))
    }
    
    func totalTimePlayed(forSize size: Int) -> Int {
        defaults.integer(forKey: key("totalTimePlayed", size: size))
    }
    
    func averageTime(forSize size: Int) -> Int {
        let won = gamesWon(forSize: size)
        guard won > 0 else { return 0 }
        return totalTimePlayed(forSize: size) / won
    }
    
    func winRate(forSize size: Int) -> Double {
        let played = gamesPlayed(forSize: size)
        guard played > 0 else { return 0 }
        return Double(gamesWon(forSize: size)) / Double(played)
    }
    
    func bestStreak(forSize size: Int) -> Int {
        defaults.integer(forKey: key("bestStreak", size: size))
    }
    
    func currentStreak(forSize size: Int) -> Int {
        defaults.integer(forKey: key("currentStreak", size: size))
    }
    
    // MARK: - Recording
    
    func recordWin(time: Int, hintsUsed: Int, checksUsed: Int) {
        gamesPlayed += 1
        gamesWon += 1
        totalTimePlayed += time
        totalHintsUsed += hintsUsed
        totalChecksUsed += checksUsed
        
        if hintsUsed == 0 {
            gamesWonWithoutHints += 1
        }
        
        if bestTime == 0 || time < bestTime {
            bestTime = time
        }
        
        currentStreak += 1
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }
    
    func recordReveal() {
        gamesPlayed += 1
        totalReveals += 1
        currentStreak = 0
    }
    
    func recordAbandon() {
        gamesPlayed += 1
        currentStreak = 0
    }
    
    // MARK: - Formatting Helpers
    
    static func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    func resetAll() {
        let bases = ["gamesPlayed", "gamesWon", "totalTimePlayed",
                     "totalHintsUsed", "totalChecksUsed", "totalReveals",
                     "bestTime", "currentStreak", "bestStreak",
                     "gamesWonWithoutHints"]
        for size in StatsManager.allSizes {
            for base in bases {
                defaults.removeObject(forKey: key(base, size: size))
            }
        }
    }
}

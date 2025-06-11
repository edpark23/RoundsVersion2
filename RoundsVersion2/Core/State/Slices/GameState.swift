import Foundation
import SwiftUI

// MARK: - Centralized Game State
@Observable
class GameState {
    
    // MARK: - Current Game Properties
    var isGameActive = false
    var currentScore: [Int] = []
    var currentHole = 1
    var totalHoles = 18
    var gameSettings: RoundSettings?
    var courseName = ""
    var startTime: Date?
    
    // MARK: - Score Verification
    var capturedScoreImage: UIImage?
    var processedScoreImage: UIImage?
    var isProcessingScore = false
    var verifiedScores: [Int] = []
    var scoreVerificationError: String?
    
    // MARK: - Game History
    var completedRounds: [CompletedRound] = []
    var gameStats: GameStats?
    
    // MARK: - Loading States
    var isLoadingHistory = false
    var isStartingGame = false
    var isSubmittingScore = false
    
    // MARK: - UI State
    var showScoreVerification = false
    var selectedHoleForEdit: Int?
    var errorMessage: String?
    var isInitialized = false
    
    // MARK: - Private Properties
    private let serviceContainer = ServiceContainer.shared
    
    // MARK: - Initialization
    func initialize() {
        guard !isInitialized else { return }
        
        Task { @MainActor in
            await loadGameHistory()
            await loadGameStats()
            isInitialized = true
        }
    }
    
    func reset() {
        isGameActive = false
        currentScore.removeAll()
        currentHole = 1
        totalHoles = 18
        gameSettings = nil
        courseName = ""
        startTime = nil
        capturedScoreImage = nil
        processedScoreImage = nil
        verifiedScores.removeAll()
        completedRounds.removeAll()
        gameStats = nil
        errorMessage = nil
        isInitialized = false
    }
    
    // MARK: - Game Management
    @MainActor
    func startNewRound(settings: RoundSettings) async {
        guard !isGameActive else { return }
        
        self.gameSettings = settings
        isGameActive = true
        isStartingGame = true
        
        Task {
            await PerformanceMonitor.measure("GameState.startNewRound") {
                // Simulate round setup
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            }
            
            await MainActor.run {
                currentHole = 1
                isStartingGame = false
            }
        }
    }
    
    @MainActor
    func updateScore(for hole: Int, score: Int) {
        guard isGameActive, hole > 0, hole <= currentScore.count else { return }
        
        currentScore[hole - 1] = score
        
        // Auto-advance to next hole if this was the current hole
        if hole == currentHole && currentHole < currentScore.count {
            currentHole += 1
        }
    }
    
    @MainActor
    func processScoreImage(image: UIImage) async {
        guard !isProcessingScore else { return }
        
        isProcessingScore = true
        scoreVerificationError = nil
        
        Task {
            await PerformanceMonitor.measure("GameState.processScoreImage") {
                // Simulate score processing
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
            }
            
            await MainActor.run {
                // Mock processing results
                verifiedScores = [4, 5, 3, 4] // Mock scores
                processedScoreImage = image
                
                // Apply verified scores to current game
                if !verifiedScores.isEmpty {
                    for (index, score) in verifiedScores.enumerated() {
                        if index < currentScore.count {
                            updateScore(for: index + 1, score: score)
                        }
                    }
                }
                
                isProcessingScore = false
            }
        }
    }
    
    @MainActor
    func finishRound() async {
        guard isGameActive, !isSubmittingScore else { return }
        
        isSubmittingScore = true
        
        Task {
            if FeatureFlags.useOptimizedViewModels {
                await PerformanceMonitor.measure("GameState.finishRound") {
                    // Optimized round submission
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                }
            } else {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            }
            
            await MainActor.run {
                // Create completed round
                let completedRound = CompletedRound(
                    id: UUID().uuidString,
                    courseName: courseName,
                    startTime: startTime ?? Date(),
                    endTime: Date(),
                    scores: currentScore,
                    totalScore: currentScore.reduce(0, +)
                )
                
                completedRounds.insert(completedRound, at: 0)
                
                // Reset game state
                isGameActive = false
                currentScore.removeAll()
                currentHole = 1
                gameSettings = nil
                courseName = ""
                startTime = nil
                
                isSubmittingScore = false
            }
            
            // Update stats
            await loadGameStats()
        }
    }
    
    @MainActor
    func cancelRound() {
        isGameActive = false
        currentScore.removeAll()
        currentHole = 1
        gameSettings = nil
        courseName = ""
        startTime = nil
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadGameHistory() async {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        
        // Simulate loading game history
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        
        // Mock recent rounds - replace with actual data loading
        completedRounds = []
        
        isLoadingHistory = false
    }
    
    @MainActor
    private func loadGameStats() async {
        // Simulate loading game stats
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // Calculate stats from recent rounds
        let totalRounds = completedRounds.count
        let averageScore = totalRounds > 0 ? completedRounds.map { $0.totalScore }.reduce(0, +) / totalRounds : 0
        
        gameStats = GameStats(
            totalRounds: totalRounds,
            averageScore: Double(averageScore),
            bestScore: completedRounds.map { $0.totalScore }.min() ?? 0,
            currentStreak: 0
        )
    }
    
    // MARK: - Score Verification Actions
    @MainActor
    func setCapturedImage(_ image: UIImage) {
        capturedScoreImage = image
        processedScoreImage = nil
        verifiedScores.removeAll()
        scoreVerificationError = nil
    }
    
    @MainActor
    func clearScoreVerification() {
        capturedScoreImage = nil
        processedScoreImage = nil
        verifiedScores.removeAll()
        scoreVerificationError = nil
        showScoreVerification = false
    }
    
    @MainActor
    func selectHoleForEdit(_ hole: Int) {
        selectedHoleForEdit = hole
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
        scoreVerificationError = nil
    }
    
    // MARK: - Computed Properties
    var totalScore: Int {
        return currentScore.reduce(0, +)
    }
    
    var remainingHoles: Int {
        return totalHoles - currentHole + 1
    }
    
    var gameProgress: Double {
        guard totalHoles > 0 else { return 0 }
        return Double(currentHole - 1) / Double(totalHoles)
    }
    
    var canFinishRound: Bool {
        guard isGameActive else { return false }
        return currentHole > totalHoles
    }
}

// MARK: - Supporting Models
struct GameStats {
    let totalRounds: Int
    let averageScore: Double
    let bestScore: Int
    let currentStreak: Int
}

struct CompletedRound {
    let id: String
    let courseName: String
    let startTime: Date
    let endTime: Date
    let scores: [Int]
    let totalScore: Int
} 
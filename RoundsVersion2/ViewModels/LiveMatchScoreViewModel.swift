import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class LiveMatchScoreViewModel: ObservableObject {
    // MARK: - Published Properties (UI Binding)
    @Published var playerScores: [Int?] = Array(repeating: nil, count: 18)
    @Published var visibleOpponentScores: [Int?] = Array(repeating: nil, count: 18)
    @Published var isConnected: Bool = false
    @Published var matchPlayers: [UserProfile] = []
    @Published var isMatchComplete: Bool = false
    @Published var syncError: String?
    
    // MARK: - Service Dependencies
    private let scoreSyncService: ScoreSyncService
    private let matchStateManager: MatchStateManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Legacy Properties (for backward compatibility)
    @Published var opponentScores: [Int?] = Array(repeating: nil, count: 18) // Kept for existing UI
    @Published var currentUserId: String = ""
    
    private let matchId: String
    
    init(matchId: String) {
        self.matchId = matchId
        self.currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        // Initialize services
        self.scoreSyncService = ScoreSyncService(matchId: matchId)
        self.matchStateManager = MatchStateManager(matchId: matchId)
        
        setupServiceBindings()
        
        // Defer initialization to prevent Firebase cascade
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s delay
            await initializeMatch()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Service Coordination
    
    private func setupServiceBindings() {
        // Bind score sync service to UI
        scoreSyncService.$playerScores
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playerScoreDict in
                self?.updatePlayerScoresArray(from: playerScoreDict)
            }
            .store(in: &cancellables)
        
        scoreSyncService.$visibleOpponentScores
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opponentScoreDict in
                self?.updateOpponentScoresArray(from: opponentScoreDict)
            }
            .store(in: &cancellables)
        
        scoreSyncService.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
        
        scoreSyncService.$syncError
            .receive(on: DispatchQueue.main)
            .assign(to: \.syncError, on: self)
            .store(in: &cancellables)
        
        // Bind match state manager to UI
        matchStateManager.$players
            .receive(on: DispatchQueue.main)
            .assign(to: \.matchPlayers, on: self)
            .store(in: &cancellables)
        
        matchStateManager.$isMatchComplete
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMatchComplete, on: self)
            .store(in: &cancellables)
    }
    
    private func initializeMatch() async {
        // Services handle their own initialization
        // Just ensure they're properly set up
        await matchStateManager.initializeMatch()
    }
    
    private func updatePlayerScoresArray(from scoreDict: [Int: Int]) {
        var newScores = Array<Int?>(repeating: nil, count: 18)
        for (hole, score) in scoreDict {
            if hole >= 1 && hole <= 18 {
                newScores[hole - 1] = score
            }
        }
        playerScores = newScores
    }
    
    private func updateOpponentScoresArray(from scoreDict: [Int: Int]) {
        var newScores = Array<Int?>(repeating: nil, count: 18)
        for (hole, score) in scoreDict {
            if hole >= 1 && hole <= 18 {
                newScores[hole - 1] = score
            }
        }
        visibleOpponentScores = newScores
        opponentScores = newScores // Keep legacy property in sync
    }
    
    // MARK: - Public Score Management Interface
    
    /// Updates a score for the current player (this triggers all sync logic)
    func updateScore(hole: Int, score: Int, isCurrentUser: Bool = true) {
        guard hole > 0 && hole <= 18 else { return }
        
        if isCurrentUser {
            Task {
                await scoreSyncService.updatePlayerScore(hole: hole, score: score)
            }
        } else {
            // Only allow current user to update their own scores
            print("Cannot update opponent's score")
        }
    }
    
    /// Clears a score for the current player
    func clearScore(hole: Int, isCurrentUser: Bool = true) {
        guard hole > 0 && hole <= 18 else { return }
        
        if isCurrentUser {
            Task {
                await scoreSyncService.clearPlayerScore(hole: hole)
            }
        }
    }
    
    /// Batch update multiple scores (useful for scorecard scanning)
    func updateMultipleScores(_ scores: [Int: Int]) {
        Task {
            await scoreSyncService.updateMultipleScores(scores)
        }
    }
    
    /// Reset all scores (for new match)
    func resetScores() {
        playerScores = Array(repeating: nil, count: 18)
        visibleOpponentScores = Array(repeating: nil, count: 18)
        opponentScores = Array(repeating: nil, count: 18)
        
        // Clear from services as well
        Task {
            for hole in 1...18 {
                if scoreSyncService.getPlayerScore(hole: hole) != nil {
                    await scoreSyncService.clearPlayerScore(hole: hole)
                }
            }
        }
    }
    
    // MARK: - Score Calculations (Enhanced with Service Integration)
    
    /// Get total score for current player
    func getTotalScore(isCurrentUser: Bool) -> Int {
        if isCurrentUser {
            return scoreSyncService.getPlayerTotal()
        } else {
            return scoreSyncService.getVisibleOpponentTotal()
        }
    }
    
    /// Get total par for completed holes only
    func getTotalPar(isCurrentUser: Bool, getHolePar: (Int) -> Int) -> Int {
        if isCurrentUser {
            let completedHoles = scoreSyncService.playerCompletedHoles
            return completedHoles.map { getHolePar($0) }.reduce(0, +)
        } else {
            let completedHoles = Array(scoreSyncService.visibleOpponentScores.keys)
            return completedHoles.map { getHolePar($0) }.reduce(0, +)
        }
    }
    
    /// Get score to par (only for completed holes)
    func getScoreToPar(isCurrentUser: Bool, getHolePar: (Int) -> Int) -> Int {
        if isCurrentUser {
            return scoreSyncService.getPlayerScoreToPar(getHolePar: getHolePar)
        } else {
            return scoreSyncService.getVisibleOpponentScoreToPar(getHolePar: getHolePar)
        }
    }
    
    /// Check if opponent score is visible for a specific hole
    func isOpponentScoreVisible(hole: Int) -> Bool {
        return scoreSyncService.isOpponentScoreVisible(hole: hole)
    }
    
    /// Get completed holes count for player
    func getCompletedHolesCount(isCurrentUser: Bool) -> Int {
        if isCurrentUser {
            return scoreSyncService.playerCompletedHoles.count
        } else {
            return scoreSyncService.visibleOpponentScores.count
        }
    }
} 
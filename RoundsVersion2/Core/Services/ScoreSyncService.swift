import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class ScoreSyncService: ObservableObject {
    // MARK: - Published Properties
    @Published var playerCompletedHoles: Set<Int> = []
    @Published var opponentCompletedHoles: Set<Int> = []
    @Published var playerScores: [Int: Int] = [:]
    @Published var visibleOpponentScores: [Int: Int] = [:]
    @Published var isConnected = false
    @Published var syncError: String?
    
    // MARK: - Private Properties
    private let matchId: String
    private let currentUserId: String
    private let db = Firestore.firestore()
    private var playerProgressListener: ListenerRegistration?
    private var opponentProgressListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(matchId: String) {
        self.matchId = matchId
        self.currentUserId = Auth.auth().currentUser?.uid ?? ""
        setupRealtimeListeners()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
    
    // MARK: - Public Interface
    
    /// Updates a score for the current player and triggers sync
    func updatePlayerScore(hole: Int, score: Int) async {
        guard hole >= 1 && hole <= 18 else { return }
        
        // Update local state immediately for responsiveness
        playerScores[hole] = score
        playerCompletedHoles.insert(hole)
        
        // Sync to Firebase
        await syncPlayerProgress()
        
        // Check for newly visible opponent scores
        await refreshOpponentVisibility()
    }
    
    /// Removes a score for the current player
    func clearPlayerScore(hole: Int) async {
        guard hole >= 1 && hole <= 18 else { return }
        
        playerScores.removeValue(forKey: hole)
        playerCompletedHoles.remove(hole)
        
        await syncPlayerProgress()
        await refreshOpponentVisibility()
    }
    
    /// Gets the player's score for a specific hole
    func getPlayerScore(hole: Int) -> Int? {
        return playerScores[hole]
    }
    
    /// Gets the opponent's score for a specific hole (only if player has completed it)
    func getVisibleOpponentScore(hole: Int) -> Int? {
        return visibleOpponentScores[hole]
    }
    
    /// Checks if opponent score should be visible for a given hole
    func isOpponentScoreVisible(hole: Int) -> Bool {
        return playerCompletedHoles.contains(hole) && opponentCompletedHoles.contains(hole)
    }
    
    /// Gets total score for player
    func getPlayerTotal() -> Int {
        return playerScores.values.reduce(0, +)
    }
    
    /// Gets total score for opponent (only visible holes)
    func getVisibleOpponentTotal() -> Int {
        return visibleOpponentScores.values.reduce(0, +)
    }
    
    // MARK: - Private Implementation
    
    private func setupRealtimeListeners() {
        // Listen to current player's progress
        playerProgressListener = db.collection("matches").document(matchId)
            .collection("playerProgress").document(currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.syncError = "Player sync error: \(error.localizedDescription)"
                    return
                }
                
                Task { @MainActor in
                    self.isConnected = true
                    // Don't overwrite local scores - they're authoritative for current player
                }
            }
        
        // Listen to opponent's progress
        setupOpponentListener()
    }
    
    private func setupOpponentListener() {
        // Get opponent ID from match metadata first
        db.collection("matches").document(matchId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let players = data["players"] as? [String] else { return }
            
            let opponentId = players.first { $0 != self.currentUserId } ?? ""
            
            self.opponentProgressListener = self.db.collection("matches").document(self.matchId)
                .collection("playerProgress").document(opponentId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.syncError = "Opponent sync error: \(error.localizedDescription)"
                        return
                    }
                    
                    Task { @MainActor in
                        self.processOpponentUpdate(snapshot?.data())
                    }
                }
        }
    }
    
    private func processOpponentUpdate(_ data: [String: Any]?) {
        guard let data = data else { return }
        
        // Update opponent completed holes
        if let completedHolesArray = data["completedHoles"] as? [Int] {
            opponentCompletedHoles = Set(completedHolesArray)
        }
        
        // Update opponent scores (but only make visible those where player has also completed)
        if let holeScores = data["holeScores"] as? [String: Int] {
            let opponentScores: [Int: Int] = Dictionary(uniqueKeysWithValues: 
                holeScores.compactMap { (key, value) in
                    guard let hole = Int(key) else { return nil }
                    return (hole, value)
                }
            )
            
            // Apply visibility filter
            visibleOpponentScores = opponentScores.filter { hole, _ in
                playerCompletedHoles.contains(hole) && opponentCompletedHoles.contains(hole)
            }
        }
    }
    
    private func syncPlayerProgress() async {
        let progressData: [String: Any] = [
            "completedHoles": Array(playerCompletedHoles).sorted(),
            "holeScores": Dictionary(uniqueKeysWithValues: 
                playerScores.map { (hole, score) in
                    ("\(hole)", score)
                }
            ),
            "lastUpdated": FieldValue.serverTimestamp(),
            "playerId": currentUserId
        ]
        
        do {
            try await db.collection("matches").document(matchId)
                .collection("playerProgress").document(currentUserId)
                .setData(progressData, merge: true)
        } catch {
            syncError = "Failed to sync progress: \(error.localizedDescription)"
        }
    }
    
    private func refreshOpponentVisibility() async {
        // Re-filter opponent scores based on updated player progress
        let currentOpponentScores = visibleOpponentScores
        
        // Get the full opponent score data to re-apply visibility filter
        do {
            let opponentId = await getOpponentId()
            let snapshot = try await db.collection("matches").document(matchId)
                .collection("playerProgress").document(opponentId).getDocument()
            
            if let data = snapshot.data() {
                processOpponentUpdate(data)
            }
        } catch {
            syncError = "Failed to refresh opponent visibility: \(error.localizedDescription)"
        }
    }
    
    private func getOpponentId() async -> String {
        do {
            let snapshot = try await db.collection("matches").document(matchId).getDocument()
            guard let data = snapshot.data(),
                  let players = data["players"] as? [String] else { return "" }
            
            return players.first { $0 != currentUserId } ?? ""
        } catch {
            return ""
        }
    }
    
    private func cleanup() {
        playerProgressListener?.remove()
        opponentProgressListener?.remove()
        cancellables.removeAll()
    }
}

// MARK: - Convenience Extensions
extension ScoreSyncService {
    /// Batch update multiple scores (useful for scorecard import)
    func updateMultipleScores(_ scores: [Int: Int]) async {
        for (hole, score) in scores {
            playerScores[hole] = score
            playerCompletedHoles.insert(hole)
        }
        
        await syncPlayerProgress()
        await refreshOpponentVisibility()
    }
    
    /// Get player's score to par for completed holes only
    func getPlayerScoreToPar(getHolePar: (Int) -> Int) -> Int {
        let totalScore = playerScores.values.reduce(0, +)
        let totalPar = playerCompletedHoles.map { getHolePar($0) }.reduce(0, +)
        return totalScore - totalPar
    }
    
    /// Get visible opponent score to par
    func getVisibleOpponentScoreToPar(getHolePar: (Int) -> Int) -> Int {
        let totalScore = visibleOpponentScores.values.reduce(0, +)
        let totalPar = visibleOpponentScores.keys.map { getHolePar($0) }.reduce(0, +)
        return totalScore - totalPar
    }
} 
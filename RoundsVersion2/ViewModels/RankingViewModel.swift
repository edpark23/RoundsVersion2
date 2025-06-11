import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RankingViewModel: ObservableObject {
    @Published var playerRank: PlayerRanking = PlayerRanking(playerId: "default")
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    
    func loadPlayerRanking() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        db.collection("playerRankings").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load ranking: \(error.localizedDescription)"
                    return
                }
                
                if let document = document, document.exists,
                   let data = document.data() {
                    self?.playerRank = self?.parsePlayerRanking(from: data, playerId: userId) ?? PlayerRanking(playerId: userId)
                } else {
                    // Create new player ranking
                    self?.playerRank = PlayerRanking(playerId: userId)
                    self?.savePlayerRanking()
                }
            }
        }
    }
    
    func processMatchResult(
        opponentId: String,
        opponentElo: Int,
        playerScore: Int,
        opponentScore: Int
    ) {
        var opponent = PlayerRanking(playerId: opponentId, startingElo: opponentElo)
        
        // Process the match using golf-specific ELO system
        GolfELOSystem.processGolfMatch(
            player1: &playerRank,
            player2: &opponent,
            player1Score: playerScore,
            player2Score: opponentScore
        )
        
        // Save updated rankings
        savePlayerRanking()
        saveOpponentRanking(opponent)
        
        // Check for tier promotion/demotion
        checkTierChange()
    }
    
    func getTierProgress() -> Double {
        let currentTier = playerRank.currentTier
        let currentElo = playerRank.currentElo
        
        let tierStart = currentTier.eloRange.lowerBound
        let tierEnd = currentTier.eloRange.upperBound
        
        // Handle master tier (open-ended)
        if currentTier == .master {
            return 1.0
        }
        
        let progress = Double(currentElo - tierStart) / Double(tierEnd - tierStart)
        return max(0, min(1, progress))
    }
    
    func getNextTierRequirement() -> Int? {
        let currentTier = playerRank.currentTier
        
        switch currentTier {
        case .silver: return RankTier.gold.eloRange.lowerBound
        case .gold: return RankTier.platinum.eloRange.lowerBound
        case .platinum: return RankTier.master.eloRange.lowerBound
        case .master: return nil // Already at highest tier
        }
    }
    
    func getNextTier() -> RankTier? {
        let currentTier = playerRank.currentTier
        
        switch currentTier {
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return .master
        case .master: return nil
        }
    }
    
    func simulateMatch(opponentElo: Int, playerScore: Int, opponentScore: Int) -> (eloChange: Int, newTier: RankTier?) {
        var tempPlayer = playerRank
        var tempOpponent = PlayerRanking(playerId: "temp", startingElo: opponentElo)
        
        GolfELOSystem.processGolfMatch(
            player1: &tempPlayer,
            player2: &tempOpponent,
            player1Score: playerScore,
            player2Score: opponentScore
        )
        
        let eloChange = tempPlayer.currentElo - playerRank.currentElo
        let newTier = tempPlayer.currentTier != playerRank.currentTier ? tempPlayer.currentTier : nil
        
        return (eloChange, newTier)
    }
    
    // MARK: - Private Methods
    
    private func parsePlayerRanking(from data: [String: Any], playerId: String) -> PlayerRanking {
        var ranking = PlayerRanking(
            playerId: playerId,
            startingElo: data["currentElo"] as? Int ?? 1200
        )
        
        ranking.matchesPlayed = data["matchesPlayed"] as? Int ?? 0
        ranking.wins = data["wins"] as? Int ?? 0
        ranking.losses = data["losses"] as? Int ?? 0
        ranking.draws = data["draws"] as? Int ?? 0
        ranking.highestElo = data["highestElo"] as? Int ?? ranking.currentElo
        ranking.lowestElo = data["lowestElo"] as? Int ?? ranking.currentElo
        
        if let timestamp = data["lastMatchDate"] as? Timestamp {
            ranking.lastMatchDate = timestamp.dateValue()
        }
        
        // Parse ELO history
        if let historyData = data["eloHistory"] as? [[String: Any]] {
            ranking.eloHistory = historyData.compactMap { parseEloHistoryEntry(from: $0) }
        }
        
        // Update tier based on current ELO
        ranking.currentTier = RankTier.getRank(for: ranking.currentElo)
        
        return ranking
    }
    
    private func parseEloHistoryEntry(from data: [String: Any]) -> EloHistoryEntry? {
        guard let timestamp = data["date"] as? Timestamp,
              let oldElo = data["oldElo"] as? Int,
              let newElo = data["newElo"] as? Int,
              let eloChange = data["eloChange"] as? Int,
              let resultString = data["matchResult"] as? String,
              let opponentId = data["opponentId"] as? String,
              let opponentElo = data["opponentElo"] as? Int else {
            return nil
        }
        
        let matchResult: MatchResult
        switch resultString {
        case "win": matchResult = .win
        case "loss": matchResult = .loss
        case "draw": matchResult = .draw
        default: return nil
        }
        
        return EloHistoryEntry(
            date: timestamp.dateValue(),
            oldElo: oldElo,
            newElo: newElo,
            eloChange: eloChange,
            matchResult: matchResult,
            opponentId: opponentId,
            opponentElo: opponentElo
        )
    }
    
    private func savePlayerRanking() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "currentElo": playerRank.currentElo,
            "currentTier": playerRank.currentTier.rawValue,
            "matchesPlayed": playerRank.matchesPlayed,
            "wins": playerRank.wins,
            "losses": playerRank.losses,
            "draws": playerRank.draws,
            "highestElo": playerRank.highestElo,
            "lowestElo": playerRank.lowestElo,
            "lastMatchDate": playerRank.lastMatchDate ?? Date(),
            "eloHistory": playerRank.eloHistory.map { historyEntryToData($0) },
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("playerRankings").document(userId).setData(data, merge: true) { error in
            if let error = error {
                print("Error saving player ranking: \(error)")
            }
        }
    }
    
    private func saveOpponentRanking(_ opponent: PlayerRanking) {
        let data: [String: Any] = [
            "currentElo": opponent.currentElo,
            "currentTier": opponent.currentTier.rawValue,
            "matchesPlayed": opponent.matchesPlayed,
            "wins": opponent.wins,
            "losses": opponent.losses,
            "draws": opponent.draws,
            "highestElo": opponent.highestElo,
            "lowestElo": opponent.lowestElo,
            "lastMatchDate": opponent.lastMatchDate ?? Date(),
            "eloHistory": opponent.eloHistory.map { historyEntryToData($0) },
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("playerRankings").document(opponent.playerId).setData(data, merge: true)
    }
    
    private func historyEntryToData(_ entry: EloHistoryEntry) -> [String: Any] {
        return [
            "date": Timestamp(date: entry.date),
            "oldElo": entry.oldElo,
            "newElo": entry.newElo,
            "eloChange": entry.eloChange,
            "matchResult": entry.matchResult == .win ? "win" : (entry.matchResult == .loss ? "loss" : "draw"),
            "opponentId": entry.opponentId,
            "opponentElo": entry.opponentElo
        ]
    }
    
    private func checkTierChange() {
        let newTier = RankTier.getRank(for: playerRank.currentElo)
        let oldTier = playerRank.currentTier
        
        if newTier != oldTier {
            // Tier changed! You could trigger celebrations, notifications, etc.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showTierChangeNotification(from: oldTier, to: newTier)
            }
        }
    }
    
    private func showTierChangeNotification(from oldTier: RankTier, to newTier: RankTier) {
        // This could trigger a celebration animation or notification
        // For now, we'll just print it
        if newTier.eloRange.lowerBound > oldTier.eloRange.lowerBound {
            print("🎉 PROMOTED! From \(oldTier.rawValue) to \(newTier.rawValue)!")
        } else {
            print("😔 Demoted from \(oldTier.rawValue) to \(newTier.rawValue)")
        }
    }
}

// MARK: - Global Leaderboard
extension RankingViewModel {
    
    func loadGlobalLeaderboard(limit: Int = 50) -> [PlayerRanking] {
        // This would load the top players globally
        // Implementation would query Firebase for top ELO ratings
        return []
    }
    
    func loadFriendsLeaderboard() -> [PlayerRanking] {
        // This would load rankings for the player's friends
        return []
    }
    
    func getPlayerRank(in leaderboard: [PlayerRanking]) -> Int? {
        return leaderboard.firstIndex { $0.playerId == playerRank.playerId }.map { $0 + 1 }
    }
} 
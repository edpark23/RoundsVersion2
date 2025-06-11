import Foundation

// MARK: - Ranking Tiers
enum RankTier: String, CaseIterable {
    case silver = "Silver"
    case gold = "Gold" 
    case platinum = "Platinum"
    case master = "Master"
    
    var eloRange: ClosedRange<Int> {
        switch self {
        case .silver: return 1000...1499
        case .gold: return 1500...1999
        case .platinum: return 2000...2499
        case .master: return 2500...9999 // Open-ended top tier
        }
    }
    
    var color: String {
        switch self {
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .platinum: return "#E5E4E2"
        case .master: return "#FF6B35"
        }
    }
    
    var icon: String {
        switch self {
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .platinum: return "diamond.fill"
        case .master: return "flame.fill"
        }
    }
    
    static func getRank(for elo: Int) -> RankTier {
        for tier in RankTier.allCases {
            if tier.eloRange.contains(elo) {
                return tier
            }
        }
        return .master // Default to master for very high ELO
    }
}

// MARK: - ELO Calculation System
struct ELOCalculator {
    
    // K-factor determines rating volatility
    // Higher K = more dramatic rating changes
    private static let kFactor: Double = 32.0
    
    // Minimum/Maximum ELO changes to prevent extreme swings
    private static let maxEloChange: Int = 50
    private static let minEloChange: Int = 1
    
    /**
     Calculate expected probability of player1 winning against player2
     Uses standard ELO formula: 1 / (1 + 10^((rating2 - rating1) / 400))
     */
    static func expectedScore(player1Elo: Int, player2Elo: Int) -> Double {
        let eloDifference = Double(player2Elo - player1Elo)
        let exponent = eloDifference / 400.0
        return 1.0 / (1.0 + pow(10, exponent))
    }
    
    /**
     Calculate new ELO ratings after a match
     - Parameters:
        - player1Elo: Current ELO of player 1
        - player2Elo: Current ELO of player 2
        - player1Won: True if player 1 won, false if player 2 won
        - isDraw: True if the match was a tie
     - Returns: Tuple of (new player1 ELO, new player2 ELO, player1 change, player2 change)
     */
    static func calculateNewRatings(
        player1Elo: Int,
        player2Elo: Int,
        player1Won: Bool?,
        isDraw: Bool = false
    ) -> (newPlayer1Elo: Int, newPlayer2Elo: Int, player1Change: Int, player2Change: Int) {
        
        let expected1 = expectedScore(player1Elo: player1Elo, player2Elo: player2Elo)
        let expected2 = expectedScore(player1Elo: player2Elo, player2Elo: player1Elo)
        
        // Actual scores: 1 for win, 0.5 for draw, 0 for loss
        let (actual1, actual2): (Double, Double)
        if isDraw {
            actual1 = 0.5
            actual2 = 0.5
        } else if player1Won == true {
            actual1 = 1.0
            actual2 = 0.0
        } else {
            actual1 = 0.0
            actual2 = 1.0
        }
        
        // Calculate raw ELO changes
        let rawChange1 = kFactor * (actual1 - expected1)
        let rawChange2 = kFactor * (actual2 - expected2)
        
        // Apply min/max constraints
        let change1 = max(minEloChange, min(maxEloChange, Int(round(abs(rawChange1))))) * (rawChange1 >= 0 ? 1 : -1)
        let change2 = max(minEloChange, min(maxEloChange, Int(round(abs(rawChange2))))) * (rawChange2 >= 0 ? 1 : -1)
        
        let newElo1 = max(800, player1Elo + change1) // Minimum ELO floor of 800
        let newElo2 = max(800, player2Elo + change2)
        
        return (newElo1, newElo2, change1, change2)
    }
    
    /**
     Calculate potential ELO gain/loss for preview purposes
     Shows players what they could gain or lose before the match
     */
    static func previewEloChanges(
        playerElo: Int,
        opponentElo: Int
    ) -> (winGain: Int, lossChange: Int, drawChange: Int) {
        
        let winResult = calculateNewRatings(
            player1Elo: playerElo,
            player2Elo: opponentElo,
            player1Won: true
        )
        
        let lossResult = calculateNewRatings(
            player1Elo: playerElo,
            player2Elo: opponentElo,
            player1Won: false
        )
        
        let drawResult = calculateNewRatings(
            player1Elo: playerElo,
            player2Elo: opponentElo,
            player1Won: nil,
            isDraw: true
        )
        
        return (
            winGain: winResult.player1Change,
            lossChange: lossResult.player1Change,
            drawChange: drawResult.player1Change
        )
    }
}

// MARK: - Player Ranking Model
struct PlayerRanking {
    let playerId: String
    var currentElo: Int
    var currentTier: RankTier
    var matchesPlayed: Int
    var wins: Int
    var losses: Int
    var draws: Int
    var eloHistory: [EloHistoryEntry]
    var highestElo: Int
    var lowestElo: Int
    var lastMatchDate: Date?
    
    var winPercentage: Double {
        guard matchesPlayed > 0 else { return 0 }
        return Double(wins) / Double(matchesPlayed)
    }
    
    var averageEloChange: Double {
        guard !eloHistory.isEmpty else { return 0 }
        let totalChange = eloHistory.reduce(0) { $0 + $1.eloChange }
        return Double(totalChange) / Double(eloHistory.count)
    }
    
    init(playerId: String, startingElo: Int = 1200) {
        self.playerId = playerId
        self.currentElo = startingElo
        self.currentTier = RankTier.getRank(for: startingElo)
        self.matchesPlayed = 0
        self.wins = 0
        self.losses = 0
        self.draws = 0
        self.eloHistory = []
        self.highestElo = startingElo
        self.lowestElo = startingElo
        self.lastMatchDate = nil
    }
    
    mutating func updateAfterMatch(
        newElo: Int,
        eloChange: Int,
        matchResult: MatchResult,
        opponentId: String,
        opponentElo: Int
    ) {
        let oldElo = currentElo
        currentElo = newElo
        currentTier = RankTier.getRank(for: newElo)
        matchesPlayed += 1
        lastMatchDate = Date()
        
        // Update win/loss record
        switch matchResult {
        case .win: wins += 1
        case .loss: losses += 1
        case .draw: draws += 1
        }
        
        // Update ELO extremes
        highestElo = max(highestElo, newElo)
        lowestElo = min(lowestElo, newElo)
        
        // Add to history
        let historyEntry = EloHistoryEntry(
            date: Date(),
            oldElo: oldElo,
            newElo: newElo,
            eloChange: eloChange,
            matchResult: matchResult,
            opponentId: opponentId,
            opponentElo: opponentElo
        )
        eloHistory.append(historyEntry)
        
        // Keep only last 50 matches in history for performance
        if eloHistory.count > 50 {
            eloHistory.removeFirst()
        }
    }
}

// MARK: - Supporting Models
enum MatchResult {
    case win, loss, draw
}

struct EloHistoryEntry {
    let date: Date
    let oldElo: Int
    let newElo: Int
    let eloChange: Int
    let matchResult: MatchResult
    let opponentId: String
    let opponentElo: Int
}

// MARK: - Golf-Specific ELO Adaptations
struct GolfELOSystem {
    
    /**
     Determine match winner based on golf scores
     Lower score wins in golf
     */
    static func determineWinner(
        player1Score: Int,
        player2Score: Int,
        drawThreshold: Int = 0 // Exact tie
    ) -> MatchResult {
        let scoreDifference = abs(player1Score - player2Score)
        
        if scoreDifference <= drawThreshold {
            return .draw
        } else if player1Score < player2Score {
            return .win
        } else {
            return .loss
        }
    }
    
    /**
     Calculate stroke-based ELO adjustment
     Considers margin of victory in golf
     */
    static func strokeBasedEloAdjustment(
        baseEloChange: Int,
        strokeDifference: Int
    ) -> Int {
        let multiplier: Double
        
        switch abs(strokeDifference) {
        case 1: multiplier = 1.0        // Close match
        case 2...3: multiplier = 1.2     // Solid victory
        case 4...6: multiplier = 1.4     // Dominant win
        case 7...10: multiplier = 1.6    // Crushing victory
        default: multiplier = 1.8        // Legendary beatdown
        }
        
        return Int(Double(baseEloChange) * multiplier)
    }
    
    /**
     Process a completed golf match and update both players' ELO
     */
    static func processGolfMatch(
        player1: inout PlayerRanking,
        player2: inout PlayerRanking,
        player1Score: Int,
        player2Score: Int
    ) {
        let matchResult = determineWinner(
            player1Score: player1Score,
            player2Score: player2Score
        )
        
        let baseResults = ELOCalculator.calculateNewRatings(
            player1Elo: player1.currentElo,
            player2Elo: player2.currentElo,
            player1Won: matchResult == .win,
            isDraw: matchResult == .draw
        )
        
        // Apply stroke-based adjustments
        let strokeDiff = player1Score - player2Score
        let adjustedChange1 = strokeBasedEloAdjustment(
            baseEloChange: baseResults.player1Change,
            strokeDifference: strokeDiff
        )
        let adjustedChange2 = strokeBasedEloAdjustment(
            baseEloChange: baseResults.player2Change,
            strokeDifference: strokeDiff
        )
        
        // Update players
        player1.updateAfterMatch(
            newElo: player1.currentElo + adjustedChange1,
            eloChange: adjustedChange1,
            matchResult: matchResult,
            opponentId: player2.playerId,
            opponentElo: player2.currentElo
        )
        
        player2.updateAfterMatch(
            newElo: player2.currentElo + adjustedChange2,
            eloChange: adjustedChange2,
            matchResult: matchResult == .win ? .loss : (matchResult == .loss ? .win : .draw),
            opponentId: player1.playerId,
            opponentElo: player1.currentElo
        )
    }
} 
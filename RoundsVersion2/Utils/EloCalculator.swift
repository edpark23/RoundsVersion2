import Foundation

enum MatchResult {
    case win
    case loss
    case draw
    
    var score: Double {
        switch self {
        case .win: return 1.0
        case .loss: return 0.0
        case .draw: return 0.5
        }
    }
}

final class EloCalculator {
    // Constants
    static let initialElo = 400
    static let kFactor = 32 // Standard K-factor for amateur players
    
    /// Calculates the expected score for a player based on their rating and opponent's rating
    /// - Parameters:
    ///   - playerRating: The player's current ELO rating
    ///   - opponentRating: The opponent's current ELO rating
    /// - Returns: Expected score between 0 and 1
    static func calculateExpectedScore(playerRating: Int, opponentRating: Int) -> Double {
        let ratingDifference = Double(opponentRating - playerRating)
        return 1.0 / (1.0 + pow(10.0, ratingDifference / 400.0))
    }
    
    /// Calculates the new ELO rating for a player after a match
    /// - Parameters:
    ///   - currentRating: Player's current ELO rating
    ///   - opponentRating: Opponent's current ELO rating
    ///   - result: The match result from the player's perspective
    /// - Returns: The player's new ELO rating
    static func calculateNewRating(currentRating: Int, opponentRating: Int, result: MatchResult) -> Int {
        let expectedScore = calculateExpectedScore(playerRating: currentRating, opponentRating: opponentRating)
        let actualScore = result.score
        let change = Double(kFactor) * (actualScore - expectedScore)
        return currentRating + Int(round(change))
    }
    
    /// Updates ELO ratings for both players after a match
    /// - Parameters:
    ///   - player1Rating: First player's current rating
    ///   - player2Rating: Second player's current rating
    ///   - player1Result: Match result from player 1's perspective
    /// - Returns: Tuple containing new ratings (player1NewRating, player2NewRating)
    static func updateRatings(player1Rating: Int, player2Rating: Int, player1Result: MatchResult) -> (player1NewRating: Int, player2NewRating: Int) {
        let player1NewRating = calculateNewRating(currentRating: player1Rating, opponentRating: player2Rating, result: player1Result)
        let player2NewRating = calculateNewRating(currentRating: player2Rating, opponentRating: player1Rating, result: player1Result == .win ? .loss : (player1Result == .loss ? .win : .draw))
        return (player1NewRating, player2NewRating)
    }
} 
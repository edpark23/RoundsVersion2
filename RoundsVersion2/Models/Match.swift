import Foundation
import FirebaseFirestore

struct Match: Identifiable, Codable {
    let id: String
    let opponentName: String
    let date: Date
    let result: String // "Won" or "Lost"
    let eloChange: Int
    
    var formattedEloChange: String {
        if eloChange > 0 {
            return "+\(eloChange)"
        }
        return "\(eloChange)"
    }
}

struct MatchData {
    let players: [String]
    let status: String
    let timestamp: FieldValue
    
    var asDictionary: [String: Any] {
        [
            "players": players,
            "status": status,
            "timestamp": timestamp
        ]
    }
}

struct StatusData {
    let status: String
    let matchId: String
    
    var asDictionary: [String: Any] {
        [
            "status": status,
            "matchId": matchId
        ]
    }
} 
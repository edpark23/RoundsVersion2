import Foundation

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
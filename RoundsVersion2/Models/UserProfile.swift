import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    let elo: Int
    let createdAt: Date
    let isAdmin: Bool
    
    var initials: String {
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }
} 
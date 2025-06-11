import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: String
    let fullName: String
    let email: String
    let elo: Int
    let createdAt: Date
    let isAdmin: Bool
    let profilePictureURL: String?
    
    var initials: String {
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            let firstName = String(components[0])
            let lastName = String(components[1])
            return "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
        } else if !fullName.isEmpty {
            return String(fullName.prefix(2)).uppercased()
        } else {
            return "U"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
} 
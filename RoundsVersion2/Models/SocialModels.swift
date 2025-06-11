import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Friend System Models

enum FriendshipStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
    case declined = "declined"
}

struct Friendship: Identifiable, Codable {
    let id: String
    let requesterId: String
    let recipientId: String
    var status: FriendshipStatus
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, requesterId: String, recipientId: String, status: FriendshipStatus = .pending) {
        self.id = id
        self.requesterId = requesterId
        self.recipientId = recipientId
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init?(document: QueryDocumentSnapshot) {
        guard
            let requesterId = document.data()["requesterId"] as? String,
            let recipientId = document.data()["recipientId"] as? String,
            let statusString = document.data()["status"] as? String,
            let status = FriendshipStatus(rawValue: statusString),
            let createdAt = (document.data()["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (document.data()["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.requesterId = requesterId
        self.recipientId = recipientId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct FriendUser: Identifiable, Codable {
    let id: String
    let fullName: String
    let username: String
    let email: String
    let profileImageURL: String?
    let handicap: Double
    let elo: Int
    let isOnline: Bool
    let lastSeen: Date?
    
    var initials: String {
        let names = fullName.split(separator: " ")
        return names.compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
    
    init?(document: QueryDocumentSnapshot) {
        guard
            let fullName = document.data()["fullName"] as? String,
            let username = document.data()["username"] as? String,
            let email = document.data()["email"] as? String
        else {
            return nil
        }
        
        self.id = document.documentID
        self.fullName = fullName
        self.username = username
        self.email = email
        self.profileImageURL = document.data()["profileImageURL"] as? String
        self.handicap = document.data()["handicap"] as? Double ?? 0.0
        self.elo = document.data()["elo"] as? Int ?? 1000
        self.isOnline = document.data()["isOnline"] as? Bool ?? false
        self.lastSeen = (document.data()["lastSeen"] as? Timestamp)?.dateValue()
    }
    
    init?(document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let fullName = data["fullName"] as? String,
            let username = data["username"] as? String,
            let email = data["email"] as? String
        else {
            return nil
        }
        
        self.id = document.documentID
        self.fullName = fullName
        self.username = username
        self.email = email
        self.profileImageURL = data["profileImageURL"] as? String
        self.handicap = data["handicap"] as? Double ?? 0.0
        self.elo = data["elo"] as? Int ?? 1000
        self.isOnline = data["isOnline"] as? Bool ?? false
        self.lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue()
    }
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUser: FriendUser
    let toUserId: String
    let status: FriendshipStatus
    let createdAt: Date
    
    init(id: String = UUID().uuidString, fromUser: FriendUser, toUserId: String, status: FriendshipStatus = .pending) {
        self.id = id
        self.fromUser = fromUser
        self.toUserId = toUserId
        self.status = status
        self.createdAt = Date()
    }
}

// MARK: - Chat Models

enum ChatType: String, CaseIterable, Codable {
    case direct = "direct"
    case group = "group"
}

struct ChatRoom: Identifiable, Codable {
    let id: String
    let type: ChatType
    let name: String?
    let participantIds: [String]
    let createdBy: String
    let createdAt: Date
    var lastMessageId: String?
    var lastMessageText: String?
    var lastMessageTimestamp: Date?
    var isActive: Bool
    
    // For direct chats, generate a name based on participants
    var displayName: String {
        if type == .group {
            return name ?? "Group Chat"
        } else {
            // For direct chats, this will be set by the view model based on the other participant
            return name ?? "Direct Message"
        }
    }
    
    init(id: String = UUID().uuidString, type: ChatType, name: String? = nil, participantIds: [String], createdBy: String) {
        self.id = id
        self.type = type
        self.name = name
        self.participantIds = participantIds
        self.createdBy = createdBy
        self.createdAt = Date()
        self.isActive = true
    }
    
    init?(document: QueryDocumentSnapshot) {
        guard
            let typeString = document.data()["type"] as? String,
            let type = ChatType(rawValue: typeString),
            let participantIds = document.data()["participantIds"] as? [String],
            let createdBy = document.data()["createdBy"] as? String,
            let createdAt = (document.data()["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.type = type
        self.name = document.data()["name"] as? String
        self.participantIds = participantIds
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastMessageId = document.data()["lastMessageId"] as? String
        self.lastMessageText = document.data()["lastMessageText"] as? String
        self.lastMessageTimestamp = (document.data()["lastMessageTimestamp"] as? Timestamp)?.dateValue()
        self.isActive = document.data()["isActive"] as? Bool ?? true
    }
}

// Enhanced ChatMessage for social features
extension ChatMessage {
    enum MessageType: String, CaseIterable, Codable {
        case text = "text"
        case image = "image"
        case system = "system"
        case gameInvite = "gameInvite"
    }
    
    var messageType: MessageType {
        // For now, default to text. This can be enhanced later
        return .text
    }
}

struct SocialChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let chatRoomId: String
    let senderId: String
    let senderName: String
    let text: String
    let type: ChatMessage.MessageType
    let timestamp: Date
    var isRead: Bool
    let metadata: [String: String]?
    
    var isFromCurrentUser: Bool {
        senderId == Auth.auth().currentUser?.uid
    }
    
    init(id: String = UUID().uuidString, chatRoomId: String, senderId: String, senderName: String, text: String, type: ChatMessage.MessageType = .text, metadata: [String: String]? = nil) {
        self.id = id
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.type = type
        self.timestamp = Date()
        self.isRead = false
        self.metadata = metadata
    }
    
    init?(document: QueryDocumentSnapshot) {
        guard
            let chatRoomId = document.data()["chatRoomId"] as? String,
            let senderId = document.data()["senderId"] as? String,
            let senderName = document.data()["senderName"] as? String,
            let text = document.data()["text"] as? String,
            let timestamp = (document.data()["timestamp"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.type = ChatMessage.MessageType(rawValue: document.data()["type"] as? String ?? "text") ?? .text
        self.timestamp = timestamp
        self.isRead = document.data()["isRead"] as? Bool ?? false
        self.metadata = document.data()["metadata"] as? [String: String]
    }
    
    static func == (lhs: SocialChatMessage, rhs: SocialChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.senderId == rhs.senderId &&
        lhs.text == rhs.text &&
        lhs.timestamp == rhs.timestamp
    }
}

// MARK: - User Search Models

struct UserSearchResult: Identifiable, Codable {
    let id: String
    let fullName: String
    let username: String
    let profileImageURL: String?
    let handicap: Double
    let elo: Int
    var friendshipStatus: FriendshipStatus?
    
    var initials: String {
        let names = fullName.split(separator: " ")
        return names.compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

// MARK: - Notification Models

enum SocialNotificationType: String, CaseIterable, Codable {
    case friendRequest = "friendRequest"
    case friendAccepted = "friendAccepted"
    case newMessage = "newMessage"
    case groupInvite = "groupInvite"
}

struct SocialNotification: Identifiable, Codable {
    let id: String
    let type: SocialNotificationType
    let fromUserId: String
    let fromUserName: String
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let metadata: [String: String]?
    
    init(id: String = UUID().uuidString, type: SocialNotificationType, fromUserId: String, fromUserName: String, title: String, message: String, metadata: [String: String]? = nil) {
        self.id = id
        self.type = type
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.title = title
        self.message = message
        self.timestamp = Date()
        self.isRead = false
        self.metadata = metadata
    }
} 
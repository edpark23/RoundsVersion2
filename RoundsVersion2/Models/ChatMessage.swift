import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    
    var isFromCurrentUser: Bool {
        senderId == Auth.auth().currentUser?.uid
    }
    
    init(id: String, senderId: String, text: String, timestamp: Date) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }
    
    init?(document: QueryDocumentSnapshot) {
        guard 
            let senderId = document.data()["senderId"] as? String,
            let text = document.data()["text"] as? String,
            let timestamp = (document.data()["timestamp"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.senderId == rhs.senderId &&
        lhs.text == rhs.text &&
        lhs.timestamp == rhs.timestamp
    }
} 
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MatchViewModel: ObservableObject {
    let matchId: String
    
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var errorMessage: String?
    
    private var messagesListener: ListenerRegistration?
    
    init(matchId: String) {
        self.matchId = matchId
        setupMessagesListener()
    }
    
    private func setupMessagesListener() {
        let db = Firestore.firestore()
        
        messagesListener = db.collection("matches")
            .document(matchId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                self?.messages = documents.compactMap { ChatMessage(document: $0) }
            }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let messageRef = db.collection("matches")
            .document(matchId)
            .collection("messages")
            .document()
        
        Task {
            do {
                try await messageRef.setData([
                    "senderId": userId,
                    "text": messageText,
                    "timestamp": FieldValue.serverTimestamp()
                ])
                
                messageText = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    deinit {
        messagesListener?.remove()
    }
} 
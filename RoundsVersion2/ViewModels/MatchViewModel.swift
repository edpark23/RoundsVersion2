import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class MatchViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var currentUserProfile: UserProfile?
    @Published var matchAccepted = false
    @Published var errorMessage: String?
    
    private let matchId: String
    private let db = Firestore.firestore()
    
    init(matchId: String) {
        self.matchId = matchId
        
        Task {
            await loadCurrentUser()
            await loadMatchStatus()
            listenToMessages()
        }
    }
    
    private func loadCurrentUser() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                let userProfile = UserProfile(
                    id: userId,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    elo: data["elo"] as? Int ?? 1200,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    isAdmin: data["isAdmin"] as? Bool ?? false,
                    profilePictureURL: data["profilePictureURL"] as? String
                )
                currentUserProfile = userProfile
            }
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    private func loadMatchStatus() async {
        do {
            let document = try await db.collection("matches").document(matchId).getDocument()
            if let data = document.data() {
                await MainActor.run {
                    matchAccepted = data["status"] as? String == "accepted"
                }
            }
        } catch {
            print("Error loading match status: \(error)")
        }
    }
    
    func acceptMatch() async {
        do {
            let updateData: [String: Any] = [
                "status": "accepted",
                "acceptedAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("matches").document(matchId).updateData(updateData)
            await MainActor.run {
                matchAccepted = true
            }
        } catch {
            print("Error accepting match: \(error)")
            await MainActor.run {
                errorMessage = "Failed to accept match"
            }
        }
    }
    
    func declineMatch() async {
        do {
            let updateData: [String: Any] = [
                "status": "declined",
                "declinedAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("matches").document(matchId).updateData(updateData)
        } catch {
            print("Error declining match: \(error)")
            await MainActor.run {
                errorMessage = "Failed to decline match"
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let message = ChatMessage(
            id: UUID().uuidString,
            senderId: userId,
            text: messageText,
            timestamp: Date()
        )
        
        let messageData: [String: Any] = [
            "text": message.text,
            "senderId": message.senderId,
            "timestamp": message.timestamp
        ]
        
        db.collection("matches").document(matchId)
            .collection("messages").document(message.id)
            .setData(messageData) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self?.messageText = ""
                    }
                }
            }
    }
    
    private func listenToMessages() {
        db.collection("matches").document(matchId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self,
                      let documents = querySnapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.messages = documents.compactMap { document in
                    guard let text = document.data()["text"] as? String,
                          let senderId = document.data()["senderId"] as? String,
                          let timestamp = document.data()["timestamp"] as? Timestamp
                    else { return nil }
                    
                    return ChatMessage(
                        id: document.documentID,
                        senderId: senderId,
                        text: text,
                        timestamp: timestamp.dateValue()
                    )
                }
            }
    }
    
    func updateSelectedCourse(course: GolfCourseSelectorViewModel.GolfCourseDetails, tee: GolfCourseSelectorViewModel.TeeDetails, settings: RoundSettings? = nil) async throws {
        var updateData: [String: Any] = [
            "courseId": course.id,
            "courseName": course.clubName,
            "courseLocation": "\(course.city), \(course.state)",
            "selectedTee": [
                "name": tee.teeName,
                "totalYards": tee.totalYards,
                "courseRating": tee.courseRating,
                "slopeRating": tee.slopeRating
            ],
            "courseSelectedAt": FieldValue.serverTimestamp()
        ]
        
        // Add round settings if provided
        if let settings = settings {
            updateData["roundSettings"] = [
                "concedePutt": settings.concedePutt,
                "puttingAssist": settings.puttingAssist,
                "greenSpeed": settings.greenSpeed,
                "windStrength": settings.windStrength,
                "mulligans": settings.mulligans,
                "caddyAssist": settings.caddyAssist
            ]
        }
        
        try await db.collection("matches").document(matchId).updateData(updateData)
    }
    
    func forfeitMatch() async {
        do {
            let updateData: [String: Any] = [
                "status": "forfeited",
                "forfeitedAt": FieldValue.serverTimestamp(),
                "forfeitedBy": Auth.auth().currentUser?.uid ?? ""
            ]
            try await db.collection("matches").document(matchId).updateData(updateData)
        } catch {
            print("Error forfeiting match: \(error)")
            errorMessage = "Failed to forfeit match"
        }
    }
} 
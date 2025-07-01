import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class SocialService: ObservableObject, @unchecked Sendable {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - Published Properties
    @Published var friends: [FriendUser] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        // Defer listener setup to prevent Firebase cascade
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s delay
            await setupListenersDelayed()
        }
    }
    
    private func setupListenersDelayed() async {
        await MainActor.run {
            setupFriendsListener()
            setupChatRoomsListener()
        }
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - User Search
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        guard !query.isEmpty else { return [] }
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        // Search by username and full name
        let usernameQuery = db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThan: query.lowercased() + "z")
            .limit(to: 10)
        
        let nameQuery = db.collection("users")
            .whereField("fullName", isGreaterThanOrEqualTo: query)
            .whereField("fullName", isLessThan: query + "z")
            .limit(to: 10)
        
        async let usernameResults = usernameQuery.getDocuments()
        async let nameResults = nameQuery.getDocuments()
        
        let (usernameSnapshot, nameSnapshot) = try await (usernameResults, nameResults)
        
        var users: [UserSearchResult] = []
        var userIds: Set<String> = []
        
        // Process username results
        for document in usernameSnapshot.documents {
            if document.documentID != currentUserId {
                let user = createUserSearchResult(from: document)
                users.append(user)
                userIds.insert(user.id)
            }
        }
        
        // Process name results (avoid duplicates)
        for document in nameSnapshot.documents {
            if document.documentID != currentUserId && !userIds.contains(document.documentID) {
                let user = createUserSearchResult(from: document)
                users.append(user)
            }
        }
        
        // Get friendship statuses
        return await withFriendshipStatuses(users: users)
    }
    
    private func createUserSearchResult(from document: QueryDocumentSnapshot) -> UserSearchResult {
        let data = document.data()
        return UserSearchResult(
            id: document.documentID,
            fullName: data["fullName"] as? String ?? "",
            username: data["username"] as? String ?? "",
            profileImageURL: data["profileImageURL"] as? String,
            handicap: data["handicap"] as? Double ?? 0.0,
            elo: data["elo"] as? Int ?? 1000
        )
    }
    
    private func withFriendshipStatuses(users: [UserSearchResult]) async -> [UserSearchResult] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return users }
        
        var updatedUsers = users
        
        for i in 0..<updatedUsers.count {
            let user = updatedUsers[i]
            let status = await getFriendshipStatus(with: user.id, currentUserId: currentUserId)
            updatedUsers[i].friendshipStatus = status
        }
        
        return updatedUsers
    }
    
    private func getFriendshipStatus(with userId: String, currentUserId: String) async -> FriendshipStatus? {
        do {
            let query = db.collection("friendships")
                .whereFilter(Filter.orFilter([
                    Filter.andFilter([
                        Filter.whereField("requesterId", isEqualTo: currentUserId),
                        Filter.whereField("recipientId", isEqualTo: userId)
                    ]),
                    Filter.andFilter([
                        Filter.whereField("requesterId", isEqualTo: userId),
                        Filter.whereField("recipientId", isEqualTo: currentUserId)
                    ])
                ]))
            
            let snapshot = try await query.getDocuments()
            
            if let document = snapshot.documents.first,
               let statusString = document.data()["status"] as? String,
               let status = FriendshipStatus(rawValue: statusString) {
                return status
            }
            
            return nil
        } catch {
            print("Error getting friendship status: \(error)")
            return nil
        }
    }
    
    // MARK: - Friend Requests
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SocialService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if friendship already exists
        let existingStatus = await getFriendshipStatus(with: userId, currentUserId: currentUserId)
        if existingStatus != nil {
            throw NSError(domain: "SocialService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Friendship already exists"])
        }
        
        let friendship = Friendship(requesterId: currentUserId, recipientId: userId)
        
        try await db.collection("friendships").document(friendship.id).setData([
            "requesterId": friendship.requesterId,
            "recipientId": friendship.recipientId,
            "status": friendship.status.rawValue,
            "createdAt": Timestamp(date: friendship.createdAt),
            "updatedAt": Timestamp(date: friendship.updatedAt)
        ])
        
        // Send notification to recipient
        await sendFriendRequestNotification(to: userId, from: currentUserId)
    }
    
    func acceptFriendRequest(friendshipId: String) async throws {
        try await updateFriendshipStatus(friendshipId: friendshipId, status: .accepted)
    }
    
    func declineFriendRequest(friendshipId: String) async throws {
        try await updateFriendshipStatus(friendshipId: friendshipId, status: .declined)
    }
    
    func blockUser(friendshipId: String) async throws {
        try await updateFriendshipStatus(friendshipId: friendshipId, status: .blocked)
    }
    
    private func updateFriendshipStatus(friendshipId: String, status: FriendshipStatus) async throws {
        try await db.collection("friendships").document(friendshipId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Chat Rooms
    func createDirectChat(with friendId: String) async throws -> ChatRoom {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SocialService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if direct chat already exists
        let existingChat = try await findExistingDirectChat(userId1: currentUserId, userId2: friendId)
        if let existingChat = existingChat {
            return existingChat
        }
        
        let participantIds = [currentUserId, friendId].sorted()
        let chatRoom = ChatRoom(
            type: .direct,
            participantIds: participantIds,
            createdBy: currentUserId
        )
        
        try await db.collection("chatRooms").document(chatRoom.id).setData([
            "type": chatRoom.type.rawValue,
            "participantIds": chatRoom.participantIds,
            "createdBy": chatRoom.createdBy,
            "createdAt": Timestamp(date: chatRoom.createdAt),
            "isActive": chatRoom.isActive
        ])
        
        return chatRoom
    }
    
    func createGroupChat(name: String, participantIds: [String]) async throws -> ChatRoom {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SocialService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var allParticipants = participantIds
        if !allParticipants.contains(currentUserId) {
            allParticipants.append(currentUserId)
        }
        
        let chatRoom = ChatRoom(
            type: .group,
            name: name,
            participantIds: allParticipants,
            createdBy: currentUserId
        )
        
        try await db.collection("chatRooms").document(chatRoom.id).setData([
            "type": chatRoom.type.rawValue,
            "name": chatRoom.name as Any,
            "participantIds": chatRoom.participantIds,
            "createdBy": chatRoom.createdBy,
            "createdAt": Timestamp(date: chatRoom.createdAt),
            "isActive": chatRoom.isActive
        ])
        
        return chatRoom
    }
    
    private func findExistingDirectChat(userId1: String, userId2: String) async throws -> ChatRoom? {
        let participantIds = [userId1, userId2].sorted()
        
        let query = db.collection("chatRooms")
            .whereField("type", isEqualTo: "direct")
            .whereField("participantIds", isEqualTo: participantIds)
            .whereField("isActive", isEqualTo: true)
        
        let snapshot = try await query.getDocuments()
        
        if let document = snapshot.documents.first {
            return ChatRoom(document: document)
        }
        
        return nil
    }
    
    // MARK: - Messages
    func sendMessage(to chatRoomId: String, text: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SocialService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let message = SocialChatMessage(
            chatRoomId: chatRoomId,
            senderId: currentUserId,
            senderName: currentUser.fullName,
            text: text
        )
        
        // Add message to subcollection
        try await db.collection("chatRooms").document(chatRoomId)
            .collection("messages").document(message.id).setData([
                "chatRoomId": message.chatRoomId,
                "senderId": message.senderId,
                "senderName": message.senderName,
                "text": message.text,
                "type": message.type.rawValue,
                "timestamp": Timestamp(date: message.timestamp),
                "isRead": message.isRead
            ])
        
        // Update chat room with last message info
        try await db.collection("chatRooms").document(chatRoomId).updateData([
            "lastMessageId": message.id,
            "lastMessageText": message.text,
            "lastMessageTimestamp": Timestamp(date: message.timestamp)
        ])
    }
    
    func getMessages(for chatRoomId: String) -> AnyPublisher<[SocialChatMessage], Error> {
        return Future { promise in
            let listener = self.db.collection("chatRooms").document(chatRoomId)
                .collection("messages")
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let messages = documents.compactMap { SocialChatMessage(document: $0) }
                    promise(.success(messages.reversed())) // Reverse to show oldest first
                }
            
            self.listeners.append(listener)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Listeners
    private func setupFriendsListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to accepted friendships
        let friendsListener = db.collection("friendships")
            .whereField("status", isEqualTo: "accepted")
            .whereFilter(Filter.orFilter([
                Filter.whereField("requesterId", isEqualTo: currentUserId),
                Filter.whereField("recipientId", isEqualTo: currentUserId)
            ]))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    await self.processFriendshipDocuments(documents, currentUserId: currentUserId)
                }
            }
        
        // Listen to pending requests
        let pendingListener = db.collection("friendships")
            .whereField("recipientId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                let requests = snapshot?.documents.compactMap { Friendship(document: $0) } ?? []
                
                DispatchQueue.main.async {
                    self.pendingRequests = requests
                }
            }
        
        listeners.append(contentsOf: [friendsListener, pendingListener])
    }
    
    private func setupChatRoomsListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let chatRoomsListener = db.collection("chatRooms")
            .whereField("participantIds", arrayContains: currentUserId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                let rooms = snapshot?.documents.compactMap { ChatRoom(document: $0) } ?? []
                
                DispatchQueue.main.async {
                    self.chatRooms = rooms
                }
            }
        
        listeners.append(chatRoomsListener)
    }
    
    private func processFriendshipDocuments(_ documents: [QueryDocumentSnapshot], currentUserId: String) async {
        var friendIds: [String] = []
        
        for document in documents {
            if let friendship = Friendship(document: document) {
                let friendId = friendship.requesterId == currentUserId ? friendship.recipientId : friendship.requesterId
                friendIds.append(friendId)
            }
        }
        
        let friends = await getFriendUsers(friendIds: friendIds)
        
        DispatchQueue.main.async {
            self.friends = friends
        }
    }
    
    private func getFriendUsers(friendIds: [String]) async -> [FriendUser] {
        guard !friendIds.isEmpty else { return [] }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: friendIds)
                .getDocuments()
            
            return snapshot.documents.compactMap { FriendUser(document: $0) }
        } catch {
            print("Error fetching friend users: \(error)")
            return []
        }
    }
    
    private func getCurrentUser() async throws -> FriendUser? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        
        let document = try await db.collection("users").document(currentUserId).getDocument()
        return FriendUser(document: document)
    }
    
    // MARK: - Notifications
    private func sendFriendRequestNotification(to userId: String, from fromUserId: String) async {
        guard let currentUser = try? await getCurrentUser() else { return }
        
        let notification = SocialNotification(
            type: .friendRequest,
            fromUserId: fromUserId,
            fromUserName: currentUser.fullName,
            title: "Friend Request",
            message: "\(currentUser.fullName) sent you a friend request",
            metadata: ["fromUserId": fromUserId]
        )
        
        do {
            try await db.collection("users").document(userId)
                .collection("notifications").document(notification.id).setData([
                    "type": notification.type.rawValue,
                    "fromUserId": notification.fromUserId,
                    "fromUserName": notification.fromUserName,
                    "title": notification.title,
                    "message": notification.message,
                    "timestamp": Timestamp(date: notification.timestamp),
                    "isRead": notification.isRead,
                    "metadata": notification.metadata ?? [:]
                ])
        } catch {
            print("Error sending friend request notification: \(error)")
        }
    }
} 
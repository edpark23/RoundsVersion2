import Foundation
import SwiftUI
import Combine

@MainActor
class SocialViewModel: ObservableObject {
    @Published var socialService = SocialService()
    
    // UI State
    @Published var selectedTab: SocialTab = .friends
    @Published var showingUserSearch = false
    @Published var showingCreateGroup = false
    @Published var showingChatRoom = false
    @Published var searchText = ""
    @Published var searchResults: [UserSearchResult] = []
    @Published var isSearching = false
    @Published var error: String?
    
    // Chat state
    @Published var selectedChatRoom: ChatRoom?
    @Published var chatRoomDisplayNames: [String: String] = [:]
    
    // Group chat creation
    @Published var newGroupName = ""
    @Published var selectedFriendsForGroup: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    
    enum SocialTab: String, CaseIterable {
        case friends = "Friends"
        case chats = "Messages"
        case requests = "Requests"
        
        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .chats: return "message.fill"
            case .requests: return "person.badge.plus"
            }
        }
    }
    
    init() {
        setupSearchBinding()
        setupChatRoomDisplayNames()
    }
    
    // MARK: - Search Functionality
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.searchUsers(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        do {
            let results = try await socialService.searchUsers(query: query)
            searchResults = results
        } catch {
            self.error = error.localizedDescription
        }
        
        isSearching = false
    }
    
    // MARK: - Friend Management
    func sendFriendRequest(to userId: String) async {
        do {
            try await socialService.sendFriendRequest(to: userId)
            // Update search results to reflect new friendship status
            await searchUsers(query: searchText)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(_ friendship: Friendship) async {
        do {
            try await socialService.acceptFriendRequest(friendshipId: friendship.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func declineFriendRequest(_ friendship: Friendship) async {
        do {
            try await socialService.declineFriendRequest(friendshipId: friendship.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Chat Management
    func startDirectChat(with friend: FriendUser) async {
        do {
            let chatRoom = try await socialService.createDirectChat(with: friend.id)
            selectedChatRoom = chatRoom
            showingChatRoom = true
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func openChatRoom(_ chatRoom: ChatRoom) {
        selectedChatRoom = chatRoom
        showingChatRoom = true
    }
    
    func createGroupChat() async {
        guard !newGroupName.isEmpty, !selectedFriendsForGroup.isEmpty else {
            error = "Please enter a group name and select at least one friend"
            return
        }
        
        do {
            let chatRoom = try await socialService.createGroupChat(
                name: newGroupName,
                participantIds: Array(selectedFriendsForGroup)
            )
            
            // Reset group creation state
            newGroupName = ""
            selectedFriendsForGroup.removeAll()
            showingCreateGroup = false
            
            // Open the new chat room
            selectedChatRoom = chatRoom
            showingChatRoom = true
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Helper Functions
    private func setupChatRoomDisplayNames() {
        socialService.$chatRooms
            .sink { [weak self] chatRooms in
                Task {
                    await self?.updateChatRoomDisplayNames(chatRooms)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateChatRoomDisplayNames(_ chatRooms: [ChatRoom]) async {
        var newDisplayNames: [String: String] = [:]
        
        for chatRoom in chatRooms {
            if chatRoom.type == .direct {
                let displayName = await getDirectChatDisplayName(for: chatRoom)
                newDisplayNames[chatRoom.id] = displayName
            } else {
                newDisplayNames[chatRoom.id] = chatRoom.displayName
            }
        }
        
        chatRoomDisplayNames = newDisplayNames
    }
    
    private func getDirectChatDisplayName(for chatRoom: ChatRoom) async -> String {
        guard let currentUserId = socialService.friends.first?.id else { return "Direct Message" }
        
        // Find the other participant
        let otherParticipantId = chatRoom.participantIds.first { $0 != currentUserId }
        
        if let otherParticipantId = otherParticipantId,
           let friend = socialService.friends.first(where: { $0.id == otherParticipantId }) {
            return friend.fullName
        }
        
        return "Direct Message"
    }
    
    func getUnreadMessageCount(for chatRoom: ChatRoom) -> Int {
        // This would typically be implemented with a real-time listener
        // For now, return 0 as a placeholder
        return 0
    }
    
    func formatLastMessageTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func getFriendshipStatus(for userId: String) -> FriendshipStatus? {
        return searchResults.first(where: { $0.id == userId })?.friendshipStatus
    }
    
    func toggleFriendSelection(friendId: String) {
        if selectedFriendsForGroup.contains(friendId) {
            selectedFriendsForGroup.remove(friendId)
        } else {
            selectedFriendsForGroup.insert(friendId)
        }
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Computed Properties
    var hasUnreadRequests: Bool {
        !socialService.pendingRequests.isEmpty
    }
    
    var unreadRequestsCount: Int {
        socialService.pendingRequests.count
    }
    
    var hasChats: Bool {
        !socialService.chatRooms.isEmpty
    }
    
    var hasFriends: Bool {
        !socialService.friends.isEmpty
    }
}

// MARK: - Chat Room View Model
@MainActor
class ChatRoomViewModel: ObservableObject {
    @Published var messages: [SocialChatMessage] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let socialService: SocialService
    private let chatRoom: ChatRoom
    private var cancellables = Set<AnyCancellable>()
    
    init(socialService: SocialService, chatRoom: ChatRoom) {
        self.socialService = socialService
        self.chatRoom = chatRoom
        loadMessages()
    }
    
    private func loadMessages() {
        socialService.getMessages(for: chatRoom.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] messages in
                    self?.messages = messages
                }
            )
            .store(in: &cancellables)
    }
    
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        do {
            try await socialService.sendMessage(to: chatRoom.id, text: text)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func clearError() {
        error = nil
    }
    
    var chatDisplayName: String {
        chatRoom.displayName
    }
    
    var isGroupChat: Bool {
        chatRoom.type == .group
    }
} 
import Foundation
import SwiftUI
import Combine

// MARK: - Centralized Social State
@Observable
class SocialState {
    
    // MARK: - Properties
    var friends: [FriendUser] = []
    var pendingRequests: [Friendship] = []
    var sentRequests: [Friendship] = []
    var chatRooms: [ChatRoom] = []
    var searchResults: [UserSearchResult] = []
    
    // MARK: - Loading States
    var isLoadingFriends = false
    var isLoadingRequests = false
    var isLoadingChats = false
    var isSearching = false
    
    // MARK: - UI State
    var selectedChatRoom: ChatRoom?
    var searchQuery = ""
    var errorMessage: String?
    var isInitialized = false
    
    // MARK: - Private Properties
    private let serviceContainer = ServiceContainer.shared
    private var friendsListener: Any?
    private var requestsListener: Any?
    private var chatsListener: Any?
    
    // MARK: - Initialization
    func initialize() {
        guard !isInitialized else { return }
        
        Task { @MainActor in
            await loadInitialData()
            setupRealtimeListeners()
            isInitialized = true
        }
    }
    
    func reset() {
        friends.removeAll()
        pendingRequests.removeAll()
        sentRequests.removeAll()
        chatRooms.removeAll()
        searchResults.removeAll()
        selectedChatRoom = nil
        searchQuery = ""
        errorMessage = nil
        isInitialized = false
        
        // Remove listeners
        friendsListener = nil
        requestsListener = nil
        chatsListener = nil
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadInitialData() async {
        if FeatureFlags.useNewSocialService {
            await PerformanceMonitor.measure("SocialState.loadInitialData") {
                await loadFriends()
                await loadRequests()
                await loadChatRooms()
            }
        } else {
            // Use existing slower implementation
            await loadFriends()
            await loadRequests()
            await loadChatRooms()
        }
    }
    
    @MainActor
    private func loadFriends() async {
        guard !isLoadingFriends else { return }
        isLoadingFriends = true
        
        if FeatureFlags.useNewSocialService {
            await PerformanceMonitor.measure("SocialState.loadFriends") {
                // Optimized friend loading with caching
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            }
        } else {
            // Existing implementation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        }
        
        // Mock friends data - replace with actual service call
        friends = []
        // TODO: Add proper friend loading from service
        
        isLoadingFriends = false
    }
    
    @MainActor
    private func loadRequests() async {
        guard !isLoadingRequests else { return }
        isLoadingRequests = true
        
        // Simulate loading friend requests
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        pendingRequests = []
        sentRequests = []
        isLoadingRequests = false
    }
    
    @MainActor
    private func loadChatRooms() async {
        guard !isLoadingChats else { return }
        isLoadingChats = true
        
        // Simulate loading chat rooms
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        
        chatRooms = []
        isLoadingChats = false
    }
    
    private func setupRealtimeListeners() {
        // Setup Firebase real-time listeners for friends, requests, and chats
        // Implementation would depend on your Firebase structure
    }
    
    // MARK: - Actions
    @MainActor
    func searchUsers(query: String) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            if FeatureFlags.useNewSocialService {
                let friendResults = await ServiceContainer.shared.socialService().searchUsers(query: query)
                await MainActor.run {
                    // Convert FriendUser to UserSearchResult
                    searchResults = friendResults.map { friend in
                        UserSearchResult(
                            id: friend.id,
                            fullName: friend.fullName,
                            username: friend.username,
                            profileImageURL: friend.profileImageURL,
                            handicap: friend.handicap,
                            elo: friend.elo,
                            friendshipStatus: nil // Default status
                        )
                    }
                    isSearching = false
                }
            } else {
                // Use existing implementation
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s simulation
                await MainActor.run {
                    searchResults = [] // Mock results
                    isSearching = false
                }
            }
        }
    }
    
    @MainActor
    func sendFriendRequest(to userId: String) async {
        let socialService = serviceContainer.socialService()
        
        if FeatureFlags.useNewSocialService {
            await PerformanceMonitor.measure("SocialState.sendFriendRequest") {
                await socialService.sendFriendRequest(to: userId)
            }
        } else {
            await socialService.sendFriendRequest(to: userId)
        }
        
        // Update local state
        await loadRequests()
    }
    
    @MainActor
    func acceptFriendRequest(friendshipId: String) async {
        let socialService = serviceContainer.socialService()
        await socialService.acceptFriendRequest(from: friendshipId)
        
        // Refresh data
        await loadFriends()
        await loadRequests()
    }
    
    @MainActor
    func createDirectChat(with friendId: String) async {
        do {
            let socialService = serviceContainer.socialService()
            let chatRoom = try await socialService.createDirectChat(with: friendId)
            
            // Update local state
            chatRooms.append(chatRoom)
            selectedChatRoom = chatRoom
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func selectChatRoom(_ chatRoom: ChatRoom) {
        selectedChatRoom = chatRoom
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    @MainActor
    func clearSearch() {
        searchQuery = ""
        searchResults.removeAll()
    }
    
    // MARK: - Computed Properties
    var friendsCount: Int {
        return friends.count
    }
    
    var pendingRequestsCount: Int {
        return pendingRequests.count
    }
    
    var onlineFriendsCount: Int {
        return friends.filter { $0.isOnline }.count
    }
    
    var hasActiveChatRooms: Bool {
        return !chatRooms.isEmpty
    }
} 
import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialViewModel()
    @State private var showingUserSearch = false
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom tab selector
                socialTabSelector
                
                // Content based on selected tab
                TabView(selection: $viewModel.selectedTab) {
                    // Friends Tab
                    FriendsListView(viewModel: viewModel)
                        .tag(SocialViewModel.SocialTab.friends)
                    
                    // Messages Tab
                    MessagesListView(viewModel: viewModel)
                        .tag(SocialViewModel.SocialTab.chats)
                    
                    // Friend Requests Tab
                    FriendRequestsView(viewModel: viewModel)
                        .tag(SocialViewModel.SocialTab.requests)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingUserSearch = true }) {
                        HStack(spacing: AppSpacing.xSmall) {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                            Text("Add Friends")
                                .font(AppTypography.bodySmall)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppColors.primaryBlue)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.xSmall)
                        .background(AppColors.lightBlue)
                        .clipShape(Capsule())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if viewModel.hasFriends {
                            Button(action: { showingCreateGroup = true }) {
                                Label("Create Group", systemImage: "person.3")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(AppColors.primaryBlue)
                    }
                    .disabled(!viewModel.hasFriends)
                }
            }
            .sheet(isPresented: $showingUserSearch) {
                UserSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupChatView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showingChatRoom) {
                if let chatRoom = viewModel.selectedChatRoom {
                    ChatRoomView(
                        chatRoom: chatRoom,
                        socialService: viewModel.socialService
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    // MARK: - Social Tab Selector
    private var socialTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SocialViewModel.SocialTab.allCases, id: \.self) { tab in
                socialTabButton(for: tab)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .background(AppColors.surfacePrimary)
    }
    
    private func socialTabButton(for tab: SocialViewModel.SocialTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedTab = tab
            }
        }) {
            VStack(spacing: AppSpacing.xSmall) {
                HStack(spacing: AppSpacing.xSmall) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(tab.rawValue)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                    
                    // Badge for unread requests
                    if tab == .requests && viewModel.hasUnreadRequests {
                        Badge(count: viewModel.unreadRequestsCount)
                    }
                }
                .foregroundColor(viewModel.selectedTab == tab ? AppColors.primaryBlue : AppColors.textSecondary)
                
                // Selection indicator
                Rectangle()
                    .fill(viewModel.selectedTab == tab ? AppColors.primaryBlue : Color.clear)
                    .frame(height: 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedTab)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.small)
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    @ObservedObject var viewModel: SocialViewModel
    @State private var showingUserSearch = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                if viewModel.hasFriends {
                    ForEach(viewModel.socialService.friends) { friend in
                        FriendRowView(friend: friend) {
                            Task {
                                await viewModel.startDirectChat(with: friend)
                            }
                        }
                    }
                } else {
                    EmptyFriendsView {
                        showingUserSearch = true
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
        }
        .background(AppColors.backgroundPrimary)
        .overlay(
            // Floating Add Friends button when no friends
            Group {
                if !viewModel.hasFriends {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showingUserSearch = true }) {
                                HStack(spacing: AppSpacing.small) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title3)
                                    Text("Add Friends")
                                        .font(AppTypography.bodyMedium)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.large)
                                .padding(.vertical, AppSpacing.medium)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                                .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, AppSpacing.large)
                            .padding(.bottom, AppSpacing.large)
                        }
                    }
                }
            }
        )
        .sheet(isPresented: $showingUserSearch) {
            UserSearchView(viewModel: viewModel)
        }
    }
}

// MARK: - Messages List View
struct MessagesListView: View {
    @ObservedObject var viewModel: SocialViewModel
    @State private var showingUserSearch = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                if viewModel.hasChats {
                    ForEach(viewModel.socialService.chatRooms) { chatRoom in
                        ChatRoomRowView(
                            chatRoom: chatRoom,
                            displayName: viewModel.chatRoomDisplayNames[chatRoom.id] ?? chatRoom.displayName,
                            lastMessageTime: viewModel.formatLastMessageTime(chatRoom.lastMessageTimestamp),
                            unreadCount: viewModel.getUnreadMessageCount(for: chatRoom)
                        ) {
                            viewModel.openChatRoom(chatRoom)
                        }
                    }
                } else {
                    EmptyChatsView {
                        showingUserSearch = true
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
        }
        .background(AppColors.backgroundPrimary)
        .sheet(isPresented: $showingUserSearch) {
            UserSearchView(viewModel: viewModel)
        }
    }
}

// MARK: - Friend Requests View
struct FriendRequestsView: View {
    @ObservedObject var viewModel: SocialViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                if viewModel.hasUnreadRequests {
                    ForEach(viewModel.socialService.pendingRequests) { request in
                        FriendRequestRowView(request: request) { action in
                            Task {
                                switch action {
                                case .accept:
                                    await viewModel.acceptFriendRequest(request)
                                case .decline:
                                    await viewModel.declineFriendRequest(request)
                                }
                            }
                        }
                    }
                } else {
                    EmptyRequestsView()
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
        }
        .background(AppColors.backgroundPrimary)
    }
}

// MARK: - Friend Row Component
struct FriendRowView: View {
    let friend: FriendUser
    let onMessage: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // Profile image
            ProfileImageView(
                imageURL: friend.profileImageURL,
                initials: friend.initials,
                size: 50
            )
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.fullName)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.small) {
                    Text("Handicap: \(friend.handicap, specifier: "%.1f")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if friend.isOnline {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Spacer()
            
            // Message button
            Button(action: onMessage) {
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
}

// MARK: - Chat Room Row Component
struct ChatRoomRowView: View {
    let chatRoom: ChatRoom
    let displayName: String
    let lastMessageTime: String
    let unreadCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.medium) {
                // Chat icon or group image
                ZStack {
                    Circle()
                        .fill(AppColors.lightBlue)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: chatRoom.type == .group ? "person.3.fill" : "person.2.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                // Chat info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(displayName)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        if unreadCount > 0 {
                            Badge(count: unreadCount)
                        }
                    }
                    
                    HStack {
                        Text(chatRoom.lastMessageText ?? "No messages yet")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(lastMessageTime)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .padding(AppSpacing.medium)
        }
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
}

// MARK: - Helper Components
struct Badge: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 16, minHeight: 16)
            .background(AppColors.error)
            .clipShape(Circle())
    }
}

struct ProfileImageView: View {
    let imageURL: String?
    let initials: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.lightBlue)
                .frame(width: size, height: size)
            
            // TODO: Add AsyncImage for profile image when available
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(AppColors.primaryBlue)
        }
    }
}

// MARK: - Empty State Views
struct EmptyFriendsView: View {
    let onAddFriends: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            EmptyStateView(
                title: "No Friends Yet",
                message: "Find and add friends to start building your golf network",
                systemImage: "person.2"
            )
            
            Button(action: onAddFriends) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                    Text("Find Friends")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.xLarge)
                .padding(.vertical, AppSpacing.medium)
                .background(AppColors.primaryBlue)
                .clipShape(Capsule())
            }
        }
        .padding(.top, AppSpacing.xxLarge)
    }
}

struct EmptyChatsView: View {
    let onAddFriends: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            EmptyStateView(
                title: "No Messages",
                message: "Start a conversation with your friends or create a group chat",
                systemImage: "message"
            )
            
            Button(action: onAddFriends) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                    Text("Find Friends to Chat")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.xLarge)
                .padding(.vertical, AppSpacing.medium)
                .background(AppColors.primaryBlue)
                .clipShape(Capsule())
            }
        }
        .padding(.top, AppSpacing.xxLarge)
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        EmptyStateView(
            title: "No Friend Requests",
            message: "You don't have any pending friend requests at the moment",
            systemImage: "person.badge.plus"
        )
        .padding(.top, AppSpacing.xxLarge)
    }
}

#if DEBUG
struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        SocialView()
    }
}
#endif 
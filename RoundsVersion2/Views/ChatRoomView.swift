import SwiftUI

struct ChatRoomView: View {
    let chatRoom: ChatRoom
    let socialService: SocialService
    @StateObject private var viewModel: ChatRoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(chatRoom: ChatRoom, socialService: SocialService) {
        self.chatRoom = chatRoom
        self.socialService = socialService
        self._viewModel = StateObject(wrappedValue: ChatRoomViewModel(socialService: socialService, chatRoom: chatRoom))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                messagesView
                
                // Message input
                messageInputView
            }
            .navigationTitle(viewModel.chatDisplayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if viewModel.isGroupChat {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // TODO: Show group info
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppColors.primaryBlue)
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.small) {
                    if viewModel.messages.isEmpty {
                        emptyMessagesView
                    } else {
                        ForEach(viewModel.messages) { message in
                            SocialChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
            }
            .background(AppColors.backgroundPrimary)
            .onAppear {
                if let lastMessage = viewModel.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Messages View
    private var emptyMessagesView: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: viewModel.isGroupChat ? "person.3" : "message")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            
            Text(viewModel.isGroupChat ? "Group Chat Started" : "Start the Conversation")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(viewModel.isGroupChat ? 
                 "Say hello to everyone in the group!" : 
                 "Send your first message to start chatting")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxLarge)
    }
    
    // MARK: - Message Input View
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderLight)
            
            HStack(spacing: AppSpacing.medium) {
                // Text input
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AppTypography.bodyMedium)
                    .lineLimit(1...4)
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(20)
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            canSendMessage ? AppColors.primaryBlue : AppColors.textTertiary
                        )
                        .clipShape(Circle())
                }
                .disabled(!canSendMessage)
                .animation(.easeInOut(duration: 0.2), value: canSendMessage)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.surfacePrimary)
        }
    }
    
    private var canSendMessage: Bool {
        !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Social Chat Bubble
struct SocialChatBubble: View {
    let message: SocialChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.small) {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 2) {
                    messageBubble
                    timeStamp
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    if !message.senderName.isEmpty {
                        Text(message.senderName)
                            .font(AppTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primaryBlue)
                            .padding(.leading, AppSpacing.small)
                    }
                    
                    HStack(alignment: .bottom, spacing: AppSpacing.small) {
                        messageBubble
                        timeStamp
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private var messageBubble: some View {
        Text(message.text)
            .font(AppTypography.bodyMedium)
            .foregroundColor(message.isFromCurrentUser ? .white : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(
                message.isFromCurrentUser ? 
                AppColors.primaryBlue : 
                AppColors.surfacePrimary
            )
            .cornerRadius(
                18,
                corners: message.isFromCurrentUser ? 
                [.topLeft, .topRight, .bottomLeft] : 
                [.topLeft, .topRight, .bottomRight]
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        message.isFromCurrentUser ? Color.clear : AppColors.borderLight,
                        lineWidth: 1
                    )
            )
    }
    
    private var timeStamp: some View {
        Text(formatTime(message.timestamp))
            .font(.system(size: 10))
            .foregroundColor(AppColors.textTertiary)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        let mockChatRoom = ChatRoom(
            type: .direct,
            participantIds: ["user1", "user2"],
            createdBy: "user1"
        )
        
        ChatRoomView(
            chatRoom: mockChatRoom,
            socialService: SocialService()
        )
    }
}
#endif 
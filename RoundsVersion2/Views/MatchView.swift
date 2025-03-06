import SwiftUI
import FirebaseFirestore

struct MatchView: View {
    let matchId: String
    let opponent: UserProfile
    @StateObject private var viewModel: MatchViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(matchId: String, opponent: UserProfile) {
        self.matchId = matchId
        self.opponent = opponent
        _viewModel = StateObject(wrappedValue: MatchViewModel(matchId: matchId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Match Header
            VStack(spacing: 15) {
                // Players Section
                HStack(spacing: 20) {
                    if let currentUser = viewModel.currentUserProfile {
                        VStack {
                            OpponentProfileCard(opponent: currentUser)
                            Text("You")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("VS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    VStack {
                        OpponentProfileCard(opponent: opponent)
                        Text("Opponent")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical)
                
                // Buttons Section
                VStack(spacing: 12) {
                    Button {
                        // TODO: Implement golf course selection
                    } label: {
                        Text("Select Golf Course")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        // TODO: Implement score verification
                    } label: {
                        Text("Verify Score")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        // TODO: Implement match completion
                    } label: {
                        Text("End Match")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 2)
            
            // Chat Section
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages) { _, messages in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Message", text: $viewModel.messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.send)
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                    
                    Button {
                        viewModel.sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.messageText.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromCurrentUser ? Color.green : Color(.systemGray5))
                .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .shadow(radius: 1)
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationView {
        MatchView(
            matchId: "preview",
            opponent: UserProfile(
                id: "preview",
                fullName: "John Doe",
                email: "john@example.com",
                elo: 1200,
                createdAt: Date()
            )
        )
    }
} 
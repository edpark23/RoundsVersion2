import SwiftUI
import FirebaseFirestore

private struct DismissToRootKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissToRoot: () -> Void {
        get { self[DismissToRootKey.self] }
        set { self[DismissToRootKey.self] = newValue }
    }
}

struct MatchView: View {
    let matchId: String
    let opponent: UserProfile
    @StateObject private var viewModel: MatchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingGolfCourseSelector = false
    @State private var showingScoreVerification = false
    @State private var selectedCourse: GolfCourseSelectorViewModel.GolfCourseDetails?
    @Environment(\.dismissToRoot) private var dismissToRoot
    
    init(matchId: String, opponent: UserProfile) {
        self.matchId = matchId
        self.opponent = opponent
        _viewModel = StateObject(wrappedValue: MatchViewModel(matchId: matchId))
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Match Header
                VStack(spacing: 15) {
                    // Players Section
                    HStack(spacing: 20) {
                        if let currentUser = viewModel.currentUserProfile {
                            VStack {
                                PlayerProfileCard(profile: currentUser)
                                Text("You")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.subtleGray)
                            }
                        }
                        
                        Text("VS")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.subtleGray)
                        
                        VStack {
                            PlayerProfileCard(profile: opponent)
                            Text("Opponent")
                                .font(.subheadline)
                                .foregroundColor(AppColors.subtleGray)
                        }
                    }
                    .padding(.vertical)
                    
                    // Golf Course Section
                    VStack(spacing: 12) {
                        if let course = selectedCourse {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.clubName)
                                    .font(.headline)
                                    .foregroundColor(AppColors.primaryNavy)
                                Text("\(course.city), \(course.state)")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.subtleGray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                            .cardStyle()
                            
                            Button {
                                showingScoreVerification = true
                            } label: {
                                HStack {
                                    Image(systemName: "flag.fill")
                                    Text("Enter Scores")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .navyButton()
                        } else {
                            Button {
                                showingGolfCourseSelector = true
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Select Golf Course")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .navyButton()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding()
                
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
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.subtleGray.opacity(0.3), lineWidth: 1)
                            )
                            .submitLabel(.send)
                            .onSubmit {
                                viewModel.sendMessage()
                            }
                        
                        Button {
                            viewModel.sendMessage()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(AppColors.highlightBlue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.messageText.isEmpty)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(AppColors.primaryNavy)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.forfeitMatch()
                        dismissToRoot()
                    }
                } label: {
                    Text("Forfeit")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $showingGolfCourseSelector) {
            GolfCourseSelectorView { course in
                selectedCourse = course
                Task {
                    do {
                        try await viewModel.updateSelectedCourse(course: course)
                    } catch {
                        print("Error updating match with selected course: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $showingScoreVerification) {
            if let course = selectedCourse {
                ScoreVerificationView(matchId: matchId, selectedCourse: course)
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromCurrentUser ? AppColors.highlightBlue : Color.white)
                .foregroundColor(message.isFromCurrentUser ? .white : AppColors.primaryNavy)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(message.isFromCurrentUser ? Color.clear : AppColors.subtleGray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
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
                createdAt: Date(),
                isAdmin: false
            )
        )
    }
} 
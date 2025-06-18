import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MatchmakingView: View {
    @StateObject private var viewModel = MatchmakingViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    // Navigation state for buttons
    @State private var showingChatRoom = false
    @State private var navigateToRoundSetup = false
    @State private var navigateToCourseSelector = false
    @State private var roundSettings: RoundSettings?
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                if viewModel.matchState == .searching {
                    searchingView
                } else if viewModel.matchState == .found {
                    matchFoundView
                }
                // Cancel/Close button (if needed, can be placed at the bottom or as per design)
            }
            .onAppear {
                viewModel.matchState = .found // Temporary override for testing
                viewModel.startMatchmaking()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingChatRoom) {
            NavigationStack {
                MatchChatView(
                    matchId: viewModel.matchId ?? "",
                    opponents: viewModel.opponents
                )
            }
        }
        .navigationDestination(isPresented: $navigateToRoundSetup) {
            RoundSetupView(
                onSetupComplete: { settings in
                    // Save settings and proceed to course selection
                    self.roundSettings = settings
                    // Navigate to course selection
                    navigateToCourseSelector = true
                },
                onCancel: {
                    // Handle round setup cancellation - go back
                    navigateToRoundSetup = false
                }
            )
            .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $navigateToCourseSelector) {
            GolfCourseSelectorView { course, tee in
                // Handle course and tee selection
                print("Selected course: \(course.clubName)")
                print("Selected tee: \(tee.teeName)")
                // TODO: Continue to round confirmation or start round
                // For now, navigate back to previous screen
                navigateToCourseSelector = false
                navigateToRoundSetup = false
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    // Searching view
    private var searchingView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.subtleGray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color(red: 0/255, green: 75/255, blue: 143/255), // #004B8F - matching home view
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: viewModel.rotation))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                            viewModel.rotation = 360
                        }
                    }
            }
            
            Text("Finding your opponent...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
            
            Text("ELO Range: \(viewModel.minElo) - \(viewModel.maxElo)")
                .font(.system(size: 14))
                .foregroundColor(AppColors.subtleGray)
                .padding(.top, 4)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // Match found view - refined to match PNG more closely
    private var matchFoundView: some View {
        VStack(spacing: 0) {
            // Uniform header
            UniformHeader(
                title: "ROUNDS",
                onBackTapped: { dismiss() },
                onMenuTapped: { /* Menu action */ }
            )

            // Competitive Lobby
            VStack(alignment: .leading, spacing: 0) {
                Text("COMPETITIVE LOBBY")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                VStack(spacing: 16) {
                    ForEach(viewModel.opponents, id: \.id) { opponent in
                        OpponentRowView(opponent: opponent)
                    }
                    
                    // Show empty slots if no opponents yet (for loading state)
                    if viewModel.opponents.isEmpty {
                        ForEach(0..<1) { _ in
                            OpponentRowView(opponent: nil)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 0)
            .padding(.top, 0)

            Spacer()

            // Info note
            Text("*You must set up a round to play your solo queue within 3 days of matching. If play does not occur, there may be a penalty.")
                .font(.system(size: 13))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingChatRoom = true
                }) {
                    Text("Chat With Players")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0/255, green: 75/255, blue: 143/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color(red: 0/255, green: 75/255, blue: 143/255), lineWidth: 2)
                        )
                }
                .scaleEffect(showingChatRoom ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: showingChatRoom)
                
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    navigateToRoundSetup = true
                }) {
                    Text("Start Round")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(red: 0/255, green: 75/255, blue: 143/255))
                        )
                }
                .scaleEffect(navigateToRoundSetup ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: navigateToRoundSetup)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // Helper function to create stat items
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.subtleGray)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
        }
    }
}

// MARK: - Opponent Row Component
struct OpponentRowView: View {
    let opponent: UserProfile?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let opponent = opponent, let profileURL = opponent.profilePictureURL, !profileURL.isEmpty {
                AsyncImage(url: URL(string: profileURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(AppColors.lightBlue)
                        .overlay(
                            Text(opponent.initials)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primaryBlue)
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2)
                )
            } else if let opponent = opponent {
                // Show initials for opponents without profile pictures
                Circle()
                    .fill(AppColors.lightBlue)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(opponent.initials)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primaryBlue)
                    )
                    .overlay(
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
            } else {
                // Placeholder for loading state
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
            }
            
            // Name and ELO
            VStack(alignment: .leading, spacing: 4) {
                Text(opponent?.fullName ?? "Loading...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                if let opponent = opponent {
                    Text("ELO: \(opponent.elo)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.subtleGray)
                }
            }
            
            Spacer()
            
            // View Career Button
            Button(action: {
                // TODO: Navigate to opponent's career/profile
                print("View career for: \(opponent?.fullName ?? "unknown")")
            }) {
                Text("View Career")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0/255, green: 75/255, blue: 143/255))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(red: 0/255, green: 75/255, blue: 143/255), lineWidth: 1)
                    )
            }
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(Color.white)
        )
    }
}

// MARK: - Match Chat View (Simple Implementation)
struct MatchChatView: View {
    let matchId: String
    let opponents: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryBlue)
                    
                    Spacer()
                    
                    Text("Match Chat")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Match info button (placeholder)
                    Button {
                        // TODO: Show match info
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
                .padding()
                .background(AppColors.surfacePrimary)
                
                // Participants
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(opponents, id: \.id) { opponent in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(AppColors.lightBlue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(opponent.initials)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.primaryBlue)
                                    )
                                
                                Text(opponent.fullName.components(separatedBy: " ").first ?? "")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .background(AppColors.surfacePrimary)
            
            Divider()
            
            // Messages area
            if messages.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "message.badge")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Start the conversation!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Say hello to your match partners and discuss your upcoming round.")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                            Text(message)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Message input
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(20)
                        .submitLabel(.send)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                AppColors.textTertiary : AppColors.primaryBlue
                            )
                            .clipShape(Circle())
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(AppColors.surfacePrimary)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("You: \(messageText)")
            messageText = ""
        }
    }
}

struct MatchmakingView_Previews: PreviewProvider {
    static var previews: some View {
        MatchmakingView()
    }
} 
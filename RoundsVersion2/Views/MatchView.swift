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

struct MatchViewCourseSelector: View {
    @StateObject private var viewModel = GolfCourseSelectorViewModel()
    var onSelect: (GolfCourseSelectorViewModel.GolfCourseDetails, GolfCourseSelectorViewModel.TeeDetails) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GolfCourseSelectorView(
            viewModel: viewModel,
            onCourseAndTeeSelected: { course, tee, _ in
                onSelect(course, tee)
                dismiss()
            }
        )
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
            // Main background
            AppColors.backgroundWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navy blue header that extends to the top edge
                Color(red: 0/255, green: 75/255, blue: 143/255) // #004B8F - consistent with HomeView
                    .frame(height: 80) // Reduced from 100
                    .ignoresSafeArea(edges: .top)
                    .overlay(
                        // Header content with back button and title
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 4) { // Reduced spacing
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14)) // Smaller icon
                                    Text("Back")
                                        .font(.system(size: 14)) // Smaller font
                                }
                                .foregroundColor(.white)
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            Text("MATCH CHAT")
                                .font(.system(size: 16, weight: .bold)) // Reduced from 18
                                .tracking(0.5)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await viewModel.forfeitMatch()
                                    dismissToRoot()
                                }
                            } label: {
                                Text("Forfeit")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13)) // Reduced from 14
                                    .opacity(0.8)
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 40) // Adjusted for status bar area
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                // Content Area (Match Details & Chat)
                ZStack(alignment: .bottom) {
                    VStack {
                        ScrollView {
                            VStack(spacing: 12) { // Reduced spacing from 16
                                // Match Header Card
                                VStack(spacing: 10) { // Reduced spacing from 15
                                    // Players Section
                                    HStack(spacing: 16) { // Reduced spacing from 20
                                        if let currentUser = viewModel.currentUserProfile {
                                            VStack(spacing: 2) { // Added spacing control
                                                PlayerProfileCard(profile: currentUser)
                                                    .scaleEffect(0.9) // Scale down the profile card
                                                Text("You")
                                                    .font(.system(size: 11, weight: .medium)) // Reduced from 12
                                                    .foregroundColor(AppColors.subtleGray)
                                            }
                                        }
                                        
                                        Text("VS")
                                            .font(.title3) // Reduced from title2
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.subtleGray)
                                        
                                        VStack(spacing: 2) { // Added spacing control
                                            PlayerProfileCard(profile: opponent)
                                                .scaleEffect(0.9) // Scale down the profile card
                                            Text("Opponent")
                                                .font(.system(size: 11, weight: .medium)) // Reduced from 12
                                                .foregroundColor(AppColors.subtleGray)
                                        }
                                    }
                                    .padding(.vertical, 10) // Reduced from .vertical
                                    
                                    // Golf Course Section
                                    VStack(spacing: 8) { // Reduced spacing from 12
                                        if let course = selectedCourse {
                                            VStack(alignment: .leading, spacing: 2) { // Reduced spacing from 4
                                                Text(course.clubName)
                                                    .font(.system(size: 15, weight: .semibold)) // Adjusted from headline
                                                    .foregroundColor(AppColors.primaryNavy)
                                                Text("\(course.city), \(course.state)")
                                                    .font(.system(size: 13)) // Adjusted from subheadline
                                                    .foregroundColor(AppColors.subtleGray)
                                            }
                                            .padding(.horizontal, 12) // Reduced from padding()
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .cardStyle()
                                            
                                            Button {
                                                showingScoreVerification = true
                                            } label: {
                                                HStack(spacing: 6) { // Added spacing control
                                                    Image(systemName: "flag.fill")
                                                        .font(.system(size: 12)) // Added font size
                                                    Text("ENTER SCORES")
                                                        .font(.system(size: 12, weight: .bold)) // Reduced from 14
                                                        .tracking(0.5)
                                                }
                                                .padding(.vertical, 10) // Reduced vertical padding
                                                .padding(.horizontal, 12)
                                                .frame(maxWidth: .infinity)
                                            }
                                            .navyButton()
                                        } else {
                                            Button {
                                                showingGolfCourseSelector = true
                                            } label: {
                                                HStack(spacing: 6) { // Added spacing control
                                                    Image(systemName: "map.fill")
                                                        .font(.system(size: 12)) // Added font size
                                                    Text("SELECT GOLF COURSE")
                                                        .font(.system(size: 12, weight: .bold)) // Reduced from 14
                                                        .tracking(0.5)
                                                }
                                                .padding(.vertical, 10) // Reduced vertical padding
                                                .padding(.horizontal, 12)
                                                .frame(maxWidth: .infinity)
                                            }
                                            .navyButton()
                                        }
                                    }
                                    .padding(.horizontal, 12) // Reduced from .horizontal
                                }
                                .padding(12) // Reduced from padding()
                                .background(Color.white)
                                .cornerRadius(14) // Reduced from 16
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                .padding(.horizontal)
                                .padding(.top, 8) // Reduced from .top
                                
                                // Chat Messages
                                HStack {
                                    Text("CHAT")
                                        .font(.system(size: 13, weight: .bold)) // Reduced from 14
                                        .tracking(0.5)
                                        .foregroundColor(AppColors.primaryNavy)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 4) // Reduced from 8
                                
                                // Chat messages scrollable area
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        LazyVStack(spacing: 8) { // Reduced spacing from 12
                                            ForEach(viewModel.messages, id: \.id) { message in
                                                ChatBubble(message: message)
                                            }
                                            // Empty view for scrolling anchor
                                            Color.clear
                                                .frame(height: 1)
                                                .id("bottomAnchor")
                                        }
                                        .padding(10) // Reduced from padding()
                                    }
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(14) // Reduced from 16
                                    .padding(.horizontal)
                                    .onChange(of: viewModel.messages) { _, messages in
                                        withAnimation {
                                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                        }
                                    }
                                    .onAppear {
                                        withAnimation {
                                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                        }
                                    }
                                }
                                
                                // Add padding at the bottom to ensure content is visible above the message input
                                Color.clear.frame(height: 60) // Reduced from 70
                            }
                        }
                    }
                    
                    // Message Input at bottom of screen
                    VStack(spacing: 0) {
                        // Divider line
                        Rectangle()
                            .fill(AppColors.subtleGray.opacity(0.2))
                            .frame(height: 1)
                        
                        // Message input area
                        HStack(spacing: 10) { // Reduced spacing from 12
                            TextField("Type a message...", text: $viewModel.messageText)
                                .font(.system(size: 14)) // Added smaller font
                                .padding(10) // Reduced from 12
                                .background(Color.white)
                                .cornerRadius(18) // Reduced from 22
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18) // Reduced from 22
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
                                    .font(.system(size: 14)) // Added font size
                                    .foregroundColor(.white)
                                    .padding(10) // Reduced from 12
                                    .background(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .disabled(viewModel.messageText.isEmpty)
                        }
                        .padding(.vertical, 10) // Reduced from padding()
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingGolfCourseSelector) {
            NavigationStack {
                MatchViewCourseSelector { course, tee in
                    selectedCourse = course
                    Task {
                        do {
                            try await viewModel.updateSelectedCourse(course: course, tee: tee, settings: nil)
                        } catch {
                            print("Error updating match with selected course: \(error)")
                        }
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
        HStack(alignment: .bottom, spacing: 6) { // Reduced spacing from 8
            // Show timestamp on the left for non-user messages
            if !message.isFromCurrentUser {
                Text(formattedTime(from: message.timestamp))
                    .font(.system(size: 9)) // Reduced from 10
                    .foregroundColor(AppColors.subtleGray)
            }
            
            if message.isFromCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .font(.system(size: 14)) // Added font size
                .padding(10) // Reduced from 12
                .background(message.isFromCurrentUser 
                    ? Color(red: 0/255, green: 75/255, blue: 143/255) // #004B8F - consistent with header
                    : Color.white)
                .foregroundColor(message.isFromCurrentUser ? .white : AppColors.primaryNavy)
                .cornerRadius(14, corners: message.isFromCurrentUser // Reduced from 16
                    ? [.topLeft, .topRight, .bottomLeft] 
                    : [.topLeft, .topRight, .bottomRight])
                .overlay(
                    RoundedRectangle(cornerRadius: 14) // Reduced from 16
                        .stroke(message.isFromCurrentUser ? Color.clear : AppColors.subtleGray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1) // Reduced shadow radius
            
            // Show timestamp on the right for user messages
            if message.isFromCurrentUser {
                Text(formattedTime(from: message.timestamp))
                    .font(.system(size: 9)) // Reduced from 10
                    .foregroundColor(AppColors.subtleGray)
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    // Helper to format the timestamp
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MatchView(
                matchId: "preview",
                opponent: UserProfile(
                    id: "preview",
                    fullName: "John Doe",
                    email: "john@example.com",
                    elo: 1200,
                    createdAt: Date(),
                    isAdmin: false,
                    profilePictureURL: nil
                )
            )
        }
    }
} 
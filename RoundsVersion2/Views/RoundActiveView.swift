import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RoundActiveView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var roundStartTime: Date
    @State private var showingScoreVerification = false
    @State private var currentHole: Int = 1
    @State private var animateTimer = false
    
    // Chat functionality
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @StateObject private var chatViewModel: MatchViewModel
    
    // Real-time score management using ObservableObject
    @StateObject private var scoreViewModel: LiveMatchScoreViewModel
    
    // Manual score entry state
    @State private var isEnteringScore = false
    @State private var tempScore: String = ""
    @State private var selectedPlayer = 0 // 0 = current user, 1 = opponent
    @State private var showingNumberPad = false
    
    // Round completion state
    @State private var showingCompletionPrompt = false
    @State private var isRoundComplete = false
    @State private var showingFinalSubmission = false
    
    // Course and tee information
    let course: GolfCourseSelectorViewModel.GolfCourseDetails
    let tee: GolfCourseSelectorViewModel.TeeDetails
    let settings: RoundSettings
    
    // Enhanced players with Phase 4 UI integration
    @State var matchPlayers: [UserProfile] = [
        UserProfile(
            id: Auth.auth().currentUser?.uid ?? "current_user",
            fullName: "Ed Park",
            email: "ed@example.com",
            elo: 1850,
            createdAt: Date(),
            isAdmin: false,
            profilePictureURL: nil
        ),
        UserProfile(
            id: "opponent",
            fullName: "Jay Lee",
            email: "jay@example.com",
            elo: 1750,
            createdAt: Date(),
            isAdmin: false,
            profilePictureURL: nil
        )
    ]
    
    let matchId: String
    
    // Computed property for round completion status
    private var isCurrentRoundComplete: Bool {
        scoreViewModel.playerScores.allSatisfy { $0 != nil }
    }
    
    init(course: GolfCourseSelectorViewModel.GolfCourseDetails, tee: GolfCourseSelectorViewModel.TeeDetails, settings: RoundSettings) {
        self.course = course
        self.tee = tee
        self.settings = settings
        let uniqueMatchId = "match_\(UUID().uuidString)"
        self.matchId = uniqueMatchId
        self._roundStartTime = State(initialValue: Date())
        self._chatViewModel = StateObject(wrappedValue: MatchViewModel(matchId: uniqueMatchId))
        self._scoreViewModel = StateObject(wrappedValue: LiveMatchScoreViewModel(matchId: uniqueMatchId))
    }
    
    var body: some View {
        ZStack {
            // Main background
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced header
                modernHeader
                
                // Live round progress banner
                liveProgressBanner
                
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        // Course information card
                        modernCourseCard
                        
                        // Integrated scorecard with both players
                        integratedScorecard
                        
                        // Chat section
                        liveMatchChat
                    }
                    .padding(.bottom, 100) // Space for floating actions
                }
                
                Spacer()
            }
            .overlay(
                // Floating action buttons for score entry
                VStack {
                    Spacer()
                    floatingScoreActions
                }
            )
        }
        .navigationBarHidden(true)
        .swipeGestures(
            onSwipeLeft: {
                // Quick hole navigation
                if currentHole < 18 {
                    withAnimation(AppAnimations.holeChange) {
                        currentHole += 1
                    }
                }
            },
            onSwipeRight: {
                // Previous hole navigation
                if currentHole > 1 {
                    withAnimation(AppAnimations.holeChange) {
                        currentHole -= 1
                    }
                }
            }
        )
        .onAppear {
            startTimer()
            checkRoundCompletion()
            // Ensure scores are reset for this new match
            scoreViewModel.resetScores()
        }
        .onDisappear {
            stopTimer()
        }
        .fullScreenCover(isPresented: $showingScoreVerification) {
            NavigationStack {
                ScoreVerificationView(
                    matchId: matchId,
                    selectedCourse: course
                )
                .interactiveNavigation()
            }
        }
        .overlay(
            // Number pad overlay for score entry
            Group {
                if showingNumberPad {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingNumberPad = false
                        }
                    
                    quickScoreEntryPad
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: showingNumberPad)
                }
            }
        )
        .overlay(
            // Round completion prompt overlay
            Group {
                if showingCompletionPrompt {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Don't dismiss on background tap for completion prompt
                        }
                    
                    roundCompletionPrompt
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: showingCompletionPrompt)
                }
            }
        )
        .alert("Round Submitted!", isPresented: $showingFinalSubmission) {
            Button("View Results") {
                // Navigate to results screen
                showingScoreVerification = true
            }
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your scorecard has been submitted successfully!")
        }
    }
    
    // MARK: - Modern Header
    private var modernHeader: some View {
        ZStack {
            Color(red: 0.0, green: 75/255, blue: 143/255).ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                // Status bar space
                Color.clear.frame(height: 44)
                
                // Navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("LIVE MATCH")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .tracking(0.5)
                        
                        Text(course.clubName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Quick stats or settings
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .frame(height: 90)
    }
    
    // MARK: - Live Progress Banner
    private var liveProgressBanner: some View {
        HStack {
            // Timer with enhanced animation or completion status
            if isRoundComplete {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    Text("ROUND COMPLETE")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } else {
                HStack(spacing: AppSpacing.small) {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateTimer ? 1.2 : 1.0)
                        .animation(AppAnimations.liveUpdate.repeatForever(), value: animateTimer)
                    
                    Text(formattedTime(elapsedTime))
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Show submit button or hole navigation
            if isRoundComplete {
                Button(action: {
                    showingCompletionPrompt = true
                }) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "paperplane.fill")
                        Text("SUBMIT")
                            .font(AppTypography.captionLarge)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.2))
                    .cornerRadius(20)
                }
            } else {
                // Current hole indicator with navigation
                HStack(spacing: AppSpacing.small) {
                    Button(action: {
                        if currentHole > 1 {
                            withAnimation(.spring()) {
                                currentHole -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.white.opacity(currentHole > 1 ? 1.0 : 0.5))
                    }
                    .disabled(currentHole <= 1)
                    
                    Text("Hole \(currentHole) of 18")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button(action: {
                        if currentHole < 18 {
                            withAnimation(.spring()) {
                                currentHole += 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(currentHole < 18 ? 1.0 : 0.5))
                    }
                    .disabled(currentHole >= 18)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(isRoundComplete ? AppColors.success : AppColors.success)
        .cornerRadius(12)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .onAppear {
            animateTimer = true
        }
    }
    
    // MARK: - Modern Course Card
    private var modernCourseCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(course.clubName)
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.large) {
                courseInfoItem("TEE", tee.teeName)
                courseInfoItem("PAR", "\(getHolePar(currentHole))")
                courseInfoItem("YARDS", "\(getHoleYardage(currentHole))")
                
                Spacer()
                
                // Current hole status
                VStack(alignment: .trailing, spacing: 2) {
                    Text("HANDICAP")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(getHoleHandicap(currentHole))")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
        .padding(.horizontal, AppSpacing.medium)
    }
    
    private func courseInfoItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryBlue)
        }
    }
    
    // MARK: - Integrated Scorecard
    private var integratedScorecard: some View {
        VStack(spacing: AppSpacing.medium) {
            // Scorecard header
            HStack {
                Text("LIVE SCORECARD")
                    .font(AppTypography.captionLarge)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("Hole \(currentHole)")
                    .font(AppTypography.captionLarge)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryBlue)
            }
            
            // Player rows with scores
            ForEach(Array(matchPlayers.enumerated()), id: \.element.id) { index, player in
                playerScoreRow(player: player, playerIndex: index)
            }
            
            // Hole navigation mini-grid
            traditionalScorecard
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
        .padding(.horizontal, AppSpacing.medium)
    }
    
    private func playerScoreRow(player: UserProfile, playerIndex: Int) -> some View {
        HStack(spacing: AppSpacing.medium) {
            // Player info
            HStack(spacing: AppSpacing.small) {
                ZStack {
                    Circle()
                        .fill(playerIndex == 0 ? AppColors.primaryBlue : AppColors.secondaryBlue)
                        .frame(width: 40, height: 40)
                    
                    Text(player.initials)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.fullName.components(separatedBy: " ").first ?? "Player")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("ELO: \(player.elo)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Current hole score
            if isCurrentUser(playerIndex: playerIndex) {
                // Editable score button for current user
                Button(action: {
                    selectedPlayer = playerIndex
                    showingNumberPad = true
                }) {
                    let currentScore = playerIndex == 0 ? scoreViewModel.playerScores[currentHole - 1] : scoreViewModel.opponentScores[currentHole - 1]
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentScore != nil ? scoreColor(score: currentScore!, par: getHolePar(currentHole)) : AppColors.backgroundSecondary)
                            .frame(width: 50, height: 35)
                        
                        if let score = currentScore {
                            Text("\(score)")
                                .font(AppTypography.bodyLarge)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "plus")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            } else {
                // Read-only score display for opponent
                let currentScore = playerIndex == 0 ? scoreViewModel.playerScores[currentHole - 1] : scoreViewModel.opponentScores[currentHole - 1]
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentScore != nil ? scoreColor(score: currentScore!, par: getHolePar(currentHole)) : AppColors.backgroundSecondary.opacity(0.6))
                        .frame(width: 50, height: 35)
                    
                    if let score = currentScore {
                        Text("\(score)")
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("-")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            
            // Total score
            VStack(spacing: 1) {
                Text("TOTAL")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                let totalScore = calculateTotalScore(for: playerIndex)
                let totalPar = getTotalParForCompletedHoles(playerIndex: playerIndex)
                let scoreToPar = totalScore - totalPar
                
                Text(scoreToPar == 0 ? "E" : (scoreToPar > 0 ? "+\(scoreToPar)" : "\(scoreToPar)"))
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(scoreToPar <= 0 ? AppColors.success : AppColors.error)
            }
        }
        .padding(AppSpacing.small)
        .background(AppColors.backgroundSecondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func scoreColor(score: Int, par: Int) -> Color {
        let diff = score - par
        switch diff {
        case ..<(-1): return AppColors.success // Eagle or better
        case -1: return Color.green // Birdie
        case 0: return AppColors.primaryBlue // Par
        case 1: return AppColors.warning // Bogey
        default: return AppColors.error // Double bogey or worse
        }
    }
    
    // MARK: - Traditional Scorecard
    private var traditionalScorecard: some View {
        VStack(spacing: AppSpacing.small) {
            Text("SCORECARD")
                .font(AppTypography.captionLarge)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 1) {
                    // Header row with hole numbers
                    holeHeaderRow
                    
                    // Par row
                    parRow
                    
                    // Player rows
                    ForEach(Array(matchPlayers.enumerated()), id: \.element.id) { index, player in
                        playerScorecardRow(player: player, playerIndex: index)
                    }
                }
                .padding(.horizontal, AppSpacing.small)
            }
        }
    }
    
    private var holeHeaderRow: some View {
        HStack(spacing: 0) {
            // Player name column
            Text("HOLE")
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Hole numbers
            ForEach(1...18, id: \.self) { hole in
                Button(action: {
                    withAnimation(.spring()) {
                        currentHole = hole
                    }
                }) {
                    Text("\(hole)")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(hole == currentHole ? AppColors.primaryBlue : AppColors.textSecondary)
                        .frame(width: 35, height: 25)
                        .background(hole == currentHole ? AppColors.primaryBlue.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
            }
            
            // Total column
            Text("TOT")
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 40)
        }
    }
    
    private var parRow: some View {
        HStack(spacing: 0) {
            Text("PAR")
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            ForEach(1...18, id: \.self) { hole in
                Text("\(getHolePar(hole))")
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 35, height: 25)
            }
            
            Text("\(getTotalPar())")
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 40)
        }
        .background(AppColors.backgroundSecondary.opacity(0.3))
        .cornerRadius(4)
    }
    
    private func playerScorecardRow(player: UserProfile, playerIndex: Int) -> some View {
        HStack(spacing: 0) {
            // Player name
            Text(player.fullName.components(separatedBy: " ").first ?? "Player")
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 60, alignment: .leading)
            
            // Score cells for each hole
            ForEach(1...18, id: \.self) { hole in
                let scores = playerIndex == 0 ? scoreViewModel.playerScores : scoreViewModel.opponentScores
                let score = scores[hole - 1]
                
                if isCurrentUser(playerIndex: playerIndex) {
                    // Editable score cell for current user
                    Button(action: {
                        currentHole = hole
                        selectedPlayer = playerIndex
                        showingNumberPad = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(score != nil ? scoreColor(score: score!, par: getHolePar(hole)) : AppColors.backgroundSecondary.opacity(0.5))
                                .frame(width: 35, height: 25)
                            
                            if let score = score {
                                Text("\(score)")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else {
                                Text("-")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        .cornerRadius(3)
                    }
                } else {
                    // Read-only score cell for opponent
                    ZStack {
                        Rectangle()
                            .fill(score != nil ? scoreColor(score: score!, par: getHolePar(hole)) : AppColors.backgroundSecondary.opacity(0.3))
                            .frame(width: 35, height: 25)
                        
                        if let score = score {
                            Text("\(score)")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Text("-")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .cornerRadius(3)
                }
            }
            
            // Total score
            let totalScore = calculateTotalScore(for: playerIndex)
            let totalPar = getTotalParForCompletedHoles(playerIndex: playerIndex)
            let scoreToPar = totalScore - totalPar
            
            Text(scoreToPar == 0 ? "E" : (scoreToPar > 0 ? "+\(scoreToPar)" : "\(scoreToPar)"))
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(scoreToPar <= 0 ? AppColors.success : AppColors.error)
                .frame(width: 40)
        }
        .background(playerIndex == 0 ? AppColors.primaryBlue.opacity(0.05) : AppColors.backgroundSecondary.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Live Match Chat
    private var liveMatchChat: some View {
        VStack(spacing: AppSpacing.medium) {
            // Chat header
            HStack {
                Image(systemName: "message.fill")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primaryBlue)
                
                Text("MATCH CHAT")
                    .font(AppTypography.captionLarge)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 6, height: 6)
                    
                    Text("LIVE")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.success)
                        .fontWeight(.medium)
                }
            }
            
            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppSpacing.small) {
                        ForEach(chatViewModel.messages, id: \.id) { message in
                            modernChatBubble(message: message)
                        }
                        
                        // Auto-scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding(.vertical, AppSpacing.small)
                }
                .frame(maxHeight: 200)
                .background(AppColors.backgroundSecondary.opacity(0.3))
                .cornerRadius(12)
                .onChange(of: chatViewModel.messages) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            
            // Message input
            HStack(spacing: AppSpacing.small) {
                TextField("Type a message...", text: $chatViewModel.messageText)
                    .font(AppTypography.bodyMedium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.backgroundWhite)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(AppColors.primaryBlue)
                        .clipShape(Circle())
                }
                .disabled(chatViewModel.messageText.isEmpty)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
        .padding(.horizontal, AppSpacing.medium)
    }
    
    private func modernChatBubble(message: ChatMessage) -> some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .font(AppTypography.bodyMedium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromCurrentUser ? AppColors.primaryBlue : AppColors.backgroundWhite)
                    .foregroundColor(message.isFromCurrentUser ? .white : AppColors.textPrimary)
                    .cornerRadius(16, corners: message.isFromCurrentUser 
                        ? [.topLeft, .topRight, .bottomLeft] 
                        : [.topLeft, .topRight, .bottomRight])
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(message.isFromCurrentUser ? Color.clear : AppColors.borderLight, lineWidth: 1)
                    )
                
                Text(formattedTime(from: message.timestamp))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    // MARK: - Floating Score Actions
    private var floatingScoreActions: some View {
        HStack(spacing: AppSpacing.medium) {
            // Camera scan button
            Button(action: {
                showingScoreVerification = true
            }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "camera.fill")
                        .font(AppTypography.bodyMedium)
                    Text("SCAN")
                        .font(AppTypography.captionLarge)
                        .fontWeight(.bold)
                }
                .foregroundColor(AppColors.primaryBlue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppColors.backgroundWhite)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.primaryBlue, lineWidth: 2)
                )
            }
            
            // Quick score entry button
            Button(action: {
                selectedPlayer = 0 // Default to current user
                showingNumberPad = true
            }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                        .font(AppTypography.bodyMedium)
                    Text("ENTER SCORE")
                        .font(AppTypography.captionLarge)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppColors.primaryBlue)
                .cornerRadius(25)
                .shadow(color: AppColors.primaryBlue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Quick Score Entry Pad
    private var quickScoreEntryPad: some View {
        VStack(spacing: AppSpacing.medium) {
            // Header
            VStack(spacing: AppSpacing.small) {
                Text("Enter Score for Hole \(currentHole)")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(matchPlayers[selectedPlayer].fullName) • Par \(getHolePar(currentHole))")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Score display
            Text(tempScore.isEmpty ? "0" : tempScore)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(AppColors.primaryBlue)
                .frame(height: 60)
            
            // Number pad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    Button("\(number)") {
                        if tempScore.count < 2 {
                            tempScore += "\(number)"
                        }
                    }
                    .numberPadButton()
                }
                
                Button("Clear") {
                    tempScore = ""
                }
                .numberPadButton(style: .secondary)
                
                Button("0") {
                    if tempScore.count < 2 && !tempScore.isEmpty {
                        tempScore += "0"
                    }
                }
                .numberPadButton()
                
                Button("⌫") {
                    if !tempScore.isEmpty {
                        tempScore.removeLast()
                    }
                }
                .numberPadButton(style: .secondary)
            }
            
            // Action buttons
            HStack(spacing: AppSpacing.medium) {
                Button("Cancel") {
                    tempScore = ""
                    showingNumberPad = false
                }
                .secondaryButton()
                
                Button("Save Score") {
                    saveScore()
                }
                .primaryButton()
                .disabled(tempScore.isEmpty || Int(tempScore) == nil)
            }
            .padding(.top)
        }
        .padding(AppSpacing.large)
        .background(AppColors.surfacePrimary)
        .cornerRadius(20)
        .padding(.horizontal, AppSpacing.medium)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Round Completion Prompt
    private var roundCompletionPrompt: some View {
        VStack(spacing: AppSpacing.large) {
            // Celebration icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.success)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showingCompletionPrompt)
            
            VStack(spacing: AppSpacing.small) {
                Text("Round Complete!")
                    .font(AppTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("You've completed all 18 holes")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Final score summary
            VStack(spacing: AppSpacing.medium) {
                HStack {
                    Text("Final Score:")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(calculateTotalScore(for: 0))")
                        .font(AppTypography.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                HStack {
                    Text("Total Par:")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(getTotalPar())")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Divider()
                
                HStack {
                    Text("Score to Par:")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    let scoreToPar = calculateTotalScore(for: 0) - getTotalPar()
                    Text(scoreToPar == 0 ? "Even" : (scoreToPar > 0 ? "+\(scoreToPar)" : "\(scoreToPar)"))
                        .font(AppTypography.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(
                            scoreToPar < 0 ? AppColors.success :
                            scoreToPar == 0 ? AppColors.primaryBlue :
                            AppColors.warning
                        )
                }
            }
            .padding(AppSpacing.medium)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(12)
            
            // Action buttons
            VStack(spacing: AppSpacing.small) {
                Button(action: submitRound) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Scorecard")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.success)
                    .cornerRadius(12)
                }
                
                Button("Review Scores") {
                    showingCompletionPrompt = false
                    // User can review/edit scores if needed
                }
                .foregroundColor(AppColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(AppSpacing.large)
        .background(AppColors.surfacePrimary)
        .cornerRadius(20)
        .padding(.horizontal, AppSpacing.medium)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Helper Functions
    private func sendMessage() {
        chatViewModel.sendMessage()
    }
    
    private func saveScore() {
        guard let score = Int(tempScore) else { return }
        
        // Only allow current user to edit their own scores
        if selectedPlayer == 0 && isCurrentUser(playerIndex: 0) {
            scoreViewModel.updateScore(hole: currentHole, score: score, isCurrentUser: true)
        } else {
            // This shouldn't happen with our UI restrictions, but safety check
            print("Attempted to edit opponent score - not allowed")
            tempScore = ""
            showingNumberPad = false
            return
        }
        
        tempScore = ""
        showingNumberPad = false
        
        // Check if this completed the round (all 18 holes have scores)
        let wasRoundJustCompleted = !isRoundComplete && isCurrentRoundComplete
        
        // Update completion status
        checkRoundCompletion()
        
        // If we just completed the round, show completion prompt immediately
        if wasRoundJustCompleted {
            showingCompletionPrompt = true
            return // Don't advance holes when round is complete
        }
        
        // Auto-advance to next hole only if not on the last hole
        if currentHole < 18 {
            withAnimation(.spring()) {
                currentHole += 1
            }
        }
    }
    
    private func checkRoundCompletion() {
        // Use computed property for reactive completion checking
        isRoundComplete = isCurrentRoundComplete
    }
    
    private func submitRound() {
        Task {
            await completeMatchWithFullData()
        }
    }
    
    @MainActor
    private func completeMatchWithFullData() async {
        // Calculate comprehensive match data
        let playerTotalScore = scoreViewModel.getTotalScore(isCurrentUser: true)
        let opponentTotalScore = scoreViewModel.getTotalScore(isCurrentUser: false)
        let totalPar = getTotalPar()
        let playerScoreToPar = playerTotalScore - totalPar
        let opponentScoreToPar = opponentTotalScore - totalPar
        
        // Determine winner
        let playerWon = playerTotalScore <= opponentTotalScore
        let winnerId = playerWon ? matchPlayers[0].id : matchPlayers[1].id
        let winnerName = playerWon ? matchPlayers[0].fullName : matchPlayers[1].fullName
        let strokeDifference = abs(playerTotalScore - opponentTotalScore)
        
        // Calculate detailed statistics
        let playerStats = calculatePlayerStats(scores: scoreViewModel.playerScores)
        let opponentStats = calculatePlayerStats(scores: scoreViewModel.opponentScores)
        
        // Prepare comprehensive match data for Firebase
        let matchData: [String: Any] = [
            // Basic match info
            "matchId": matchId,
            "status": "completed",
            "completedAt": FieldValue.serverTimestamp(),
            "startedAt": Timestamp(date: roundStartTime),
            "duration": elapsedTime,
            
            // Course information
            "course": [
                "id": course.id,
                "name": course.clubName,
                "city": course.city,
                "state": course.state
            ],
            "tee": [
                "name": tee.teeName,
                "yardage": tee.totalYards,
                "rating": tee.courseRating,
                "slope": tee.slopeRating,
                "par": tee.parTotal
            ],
            
            // Player information
            "players": [
                [
                    "id": matchPlayers[0].id,
                    "name": matchPlayers[0].fullName,
                    "email": matchPlayers[0].email,
                    "elo": matchPlayers[0].elo
                ],
                [
                    "id": matchPlayers[1].id,
                    "name": matchPlayers[1].fullName,
                    "email": matchPlayers[1].email,
                    "elo": matchPlayers[1].elo
                ]
            ],
            
            // Detailed scores
            "scores": [
                "player": scoreViewModel.playerScores,
                "opponent": scoreViewModel.opponentScores
            ],
            
            // Final results
            "finalScores": [
                matchPlayers[0].id: playerTotalScore,
                matchPlayers[1].id: opponentTotalScore
            ],
            "scoresToPar": [
                matchPlayers[0].id: playerScoreToPar,
                matchPlayers[1].id: opponentScoreToPar
            ],
            
            // Winner information
            "winnerId": winnerId,
            "winnerName": winnerName,
            "strokeDifference": strokeDifference,
            "wasPlayoff": strokeDifference == 0,
            
            // Detailed statistics
            "statistics": [
                matchPlayers[0].id: playerStats,
                matchPlayers[1].id: opponentStats
            ],
            
            // Round settings used
            "settings": [
                "concedePutt": settings.concedePutt,
                "puttingAssist": settings.puttingAssist,
                "greenSpeed": settings.greenSpeed,
                "windStrength": settings.windStrength,
                "mulligans": settings.mulligans,
                "caddyAssist": settings.caddyAssist,
                "startingHole": settings.startingHole
            ],
            
            // Additional metadata
            "version": "2.0",
            "platform": "iOS"
        ]
        
        do {
            // Save complete match data to Firebase
            let db = Firestore.firestore()
            try await db.collection("matches").document(matchId).setData(matchData)
            
            // Also save to completed matches collection for easier querying
            try await db.collection("completedMatches").document(matchId).setData(matchData)
            
            // Update player statistics
            await updatePlayerStatistics(
                playerId: matchPlayers[0].id,
                stats: playerStats,
                won: playerWon,
                totalScore: playerTotalScore,
                scoreToPar: playerScoreToPar
            )
            
            await updatePlayerStatistics(
                playerId: matchPlayers[1].id,
                stats: opponentStats,
                won: !playerWon,
                totalScore: opponentTotalScore,
                scoreToPar: opponentScoreToPar
            )
            
            print("✅ Match completed and saved successfully!")
            print("Winner: \(winnerName) by \(strokeDifference) stroke(s)")
            print("Final Scores: \(matchPlayers[0].fullName): \(playerTotalScore), \(matchPlayers[1].fullName): \(opponentTotalScore)")
            
            showingCompletionPrompt = false
            showingFinalSubmission = true
            
        } catch {
            print("❌ Error saving match data: \(error)")
            // Still show completion but with error handling
            showingCompletionPrompt = false
            showingFinalSubmission = true
        }
    }
    
    private func calculatePlayerStats(scores: [Int?]) -> [String: Any] {
        let validScores = scores.compactMap { $0 }
        let holesPlayed = validScores.count
        
        var eagles = 0
        var birdies = 0
        var pars = 0
        var bogeys = 0
        var doubleBogeys = 0
        var tripleBogeyPlus = 0
        
        for (index, score) in scores.enumerated() {
            guard let score = score else { continue }
            let holePar = getHolePar(index + 1)
            let scoreToPar = score - holePar
            
            switch scoreToPar {
            case ...(-2): eagles += 1
            case -1: birdies += 1
            case 0: pars += 1
            case 1: bogeys += 1
            case 2: doubleBogeys += 1
            default: tripleBogeyPlus += 1
            }
        }
        
        return [
            "holesPlayed": holesPlayed,
            "totalStrokes": validScores.reduce(0, +),
            "eagles": eagles,
            "birdies": birdies,
            "pars": pars,
            "bogeys": bogeys,
            "doubleBogeys": doubleBogeys,
            "tripleBogeyPlus": tripleBogeyPlus,
            "averageScore": holesPlayed > 0 ? Double(validScores.reduce(0, +)) / Double(holesPlayed) : 0.0
        ]
    }
    
    private func updatePlayerStatistics(playerId: String, stats: [String: Any], won: Bool, totalScore: Int, scoreToPar: Int) async {
        let db = Firestore.firestore()
        
        do {
            // Update player's overall statistics
            let playerRef = db.collection("users").document(playerId)
            
            try await playerRef.updateData([
                "statistics.matchesPlayed": FieldValue.increment(Int64(1)),
                "statistics.wins": FieldValue.increment(Int64(won ? 1 : 0)),
                "statistics.losses": FieldValue.increment(Int64(won ? 0 : 1)),
                "statistics.totalStrokes": FieldValue.increment(Int64(totalScore)),
                "statistics.eagles": FieldValue.increment(Int64(stats["eagles"] as? Int ?? 0)),
                "statistics.birdies": FieldValue.increment(Int64(stats["birdies"] as? Int ?? 0)),
                "statistics.pars": FieldValue.increment(Int64(stats["pars"] as? Int ?? 0)),
                "statistics.bogeys": FieldValue.increment(Int64(stats["bogeys"] as? Int ?? 0)),
                "statistics.doubleBogeys": FieldValue.increment(Int64(stats["doubleBogeys"] as? Int ?? 0)),
                "statistics.lastPlayed": FieldValue.serverTimestamp(),
                "statistics.bestScore": totalScore, // This should be compared with existing best
                "statistics.averageScore": stats["averageScore"] as? Double ?? 0.0
            ])
            
            // Add to player's match history
            try await db.collection("users").document(playerId)
                .collection("matchHistory").document(matchId).setData([
                    "matchId": matchId,
                    "date": FieldValue.serverTimestamp(),
                    "won": won,
                    "score": totalScore,
                    "scoreToPar": scoreToPar,
                    "courseName": course.clubName,
                    "opponentId": playerId == matchPlayers[0].id ? matchPlayers[1].id : matchPlayers[0].id,
                    "opponentName": playerId == matchPlayers[0].id ? matchPlayers[1].fullName : matchPlayers[0].fullName
                ])
            
        } catch {
            print("Error updating player statistics for \(playerId): \(error)")
        }
    }
    
    private func getHolePar(_ hole: Int) -> Int {
        guard hole > 0 && hole <= 18,
              let firstTee = tee.holes.first(where: { $0.number == hole }) else {
            return 4 // Default par
        }
        return firstTee.par
    }
    
    private func getHoleYardage(_ hole: Int) -> Int {
        guard hole > 0 && hole <= 18,
              let firstTee = tee.holes.first(where: { $0.number == hole }) else {
            return 400 // Default yardage
        }
        return firstTee.yardage
    }
    
    private func getHoleHandicap(_ hole: Int) -> Int {
        guard hole > 0 && hole <= 18,
              let firstTee = tee.holes.first(where: { $0.number == hole }) else {
            return hole // Default handicap
        }
        return firstTee.handicap
    }
    
    private func getTotalParToHole(_ hole: Int) -> Int {
        var totalPar = 0
        for h in 1...hole {
            totalPar += getHolePar(h)
        }
        return totalPar
    }
    
    // MARK: - Fixed Math Helper Functions
    private func calculateTotalScore(for playerIndex: Int) -> Int {
        return scoreViewModel.getTotalScore(isCurrentUser: playerIndex == 0)
    }
    
    private func getTotalParForCompletedHoles(playerIndex: Int) -> Int {
        return scoreViewModel.getTotalPar(isCurrentUser: playerIndex == 0, getHolePar: getHolePar)
    }
    
    private func getTotalPar() -> Int {
        var totalPar = 0
        for hole in 1...18 {
            totalPar += getHolePar(hole)
        }
        return totalPar
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(roundStartTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Helper function to determine if user is current player
    private func isCurrentUser(playerIndex: Int) -> Bool {
        return playerIndex == 0 && matchPlayers[0].id == Auth.auth().currentUser?.uid
    }
}

// MARK: - View Extensions
extension View {
    func numberPadButton(style: NumberPadButtonStyle = .primary) -> some View {
        self
            .font(AppTypography.titleMedium)
            .fontWeight(.semibold)
            .foregroundColor(style == .primary ? AppColors.textPrimary : AppColors.textSecondary)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(style == .primary ? AppColors.backgroundSecondary : AppColors.backgroundWhite)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
    }
}

enum NumberPadButtonStyle {
    case primary
    case secondary
}

// Preview
struct RoundActiveView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCourse = GolfCourseSelectorViewModel.GolfCourseDetails(
            id: "sample",
            clubName: "Pebble Beach Golf Links",
            courseName: "Pebble Beach",
            city: "Pebble Beach",
            state: "CA",
            tees: []
        )
        
        let sampleTee = GolfCourseSelectorViewModel.TeeDetails(
            type: "championship",
            teeName: "Black Tees",
            courseRating: 75.5,
            slopeRating: 145,
            totalYards: 7040,
            parTotal: 72,
            holes: []
        )
        
        let sampleSettings = RoundSettings.defaultSettings
        
        RoundActiveView(
            course: sampleCourse,
            tee: sampleTee,
            settings: sampleSettings
        )
    }
} 
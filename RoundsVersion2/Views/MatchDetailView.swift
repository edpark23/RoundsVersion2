import SwiftUI
import FirebaseAuth

struct MatchDetailView: View {
    let match: CompletedMatch
    @Environment(\.presentationMode) var presentationMode
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private var currentUserScore: Int {
        return match.finalScores[currentUserId] ?? 0
    }
    
    private var opponentScore: Int {
        let opponentId = match.players.first { $0.id != currentUserId }?.id ?? ""
        return match.finalScores[opponentId] ?? 0
    }
    
    private var opponent: PlayerInfo? {
        return match.players.first { $0.id != currentUserId }
    }
    
    private var currentUser: PlayerInfo? {
        return match.players.first { $0.id == currentUserId }
    }
    
    private var didWin: Bool {
        return match.winnerId == currentUserId
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Match Result Header
                    matchResultHeader
                    
                    // Course Information
                    courseInfoSection
                    
                    // Detailed Scores
                    scoresSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Match Settings
                    settingsSection
                }
                .padding(.horizontal, AppSpacing.large)
                .padding(.top, AppSpacing.medium)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Match Result Header
    private var matchResultHeader: some View {
        VStack(spacing: AppSpacing.medium) {
            // Result indicator
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(didWin ? "VICTORY" : "DEFEAT")
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(didWin ? AppColors.success : AppColors.error)
                    
                    Text("by \(match.strokeDifference) stroke\(match.strokeDifference == 1 ? "" : "s")")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            
            // Player vs Opponent
            HStack(spacing: AppSpacing.large) {
                // Current User
                VStack(spacing: AppSpacing.small) {
                    Text("You")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(currentUserScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(didWin ? AppColors.success : AppColors.textPrimary)
                    
                    if let scoreToPar = match.scoresToPar[currentUserId] {
                        Text(formatScoreToPar(scoreToPar))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Text("vs")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                // Opponent
                VStack(spacing: AppSpacing.small) {
                    Text(opponent?.name ?? "Opponent")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(opponentScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(!didWin ? AppColors.success : AppColors.textPrimary)
                    
                    if let opponentId = opponent?.id,
                       let scoreToPar = match.scoresToPar[opponentId] {
                        Text(formatScoreToPar(scoreToPar))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            // Match date and duration
            VStack(spacing: 4) {
                Text(formatDate(match.completedAt))
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Duration: \(formatDuration(match.duration))")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.large)
        .background(AppColors.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Course Information
    private var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Course Details")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                InfoRow(label: "Course", value: match.course.name)
                InfoRow(label: "Location", value: "\(match.course.city), \(match.course.state)")
                InfoRow(label: "Tees", value: match.tee.name)
                InfoRow(label: "Yardage", value: "\(match.tee.yardage) yards")
                InfoRow(label: "Rating/Slope", value: "\(match.tee.rating)/\(match.tee.slope)")
                InfoRow(label: "Par", value: "\(match.tee.par)")
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Scores Section
    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Hole-by-Hole Scores")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            // Front 9
            scoreGrid(title: "Front 9", holes: Array(1...9))
            
            // Back 9
            scoreGrid(title: "Back 9", holes: Array(10...18))
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func scoreGrid(title: String, holes: [Int]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppTypography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
            
            // Header row
            HStack(spacing: 4) {
                Text("Hole")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 40, alignment: .leading)
                
                ForEach(holes, id: \.self) { hole in
                    Text("\(hole)")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 25)
                }
                
                Text("Total")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 40)
            }
            
            // Your scores
            HStack(spacing: 4) {
                Text("You")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, alignment: .leading)
                
                ForEach(holes, id: \.self) { hole in
                    let score = match.scores.player[hole - 1]
                    Text(score != nil ? "\(score!)" : "-")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 25)
                }
                
                let total = holes.compactMap { match.scores.player[$0 - 1] }.reduce(0, +)
                Text("\(total)")
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40)
            }
            
            // Opponent scores
            HStack(spacing: 4) {
                Text(opponent?.name.components(separatedBy: " ").first ?? "Opp")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, alignment: .leading)
                
                ForEach(holes, id: \.self) { hole in
                    let score = match.scores.opponent[hole - 1]
                    Text(score != nil ? "\(score!)" : "-")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 25)
                }
                
                let total = holes.compactMap { match.scores.opponent[$0 - 1] }.reduce(0, +)
                Text("\(total)")
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40)
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Match Statistics")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.large) {
                // Your stats
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Your Performance")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let stats = match.statistics[currentUserId] {
                        VStack(alignment: .leading, spacing: 2) {
                            StatLine(label: "Eagles", value: "\(stats.eagles)")
                            StatLine(label: "Birdies", value: "\(stats.birdies)")
                            StatLine(label: "Pars", value: "\(stats.pars)")
                            StatLine(label: "Bogeys", value: "\(stats.bogeys)")
                            StatLine(label: "Double+", value: "\(stats.doubleBogeys + stats.tripleBogeyPlus)")
                        }
                    }
                }
                
                Spacer()
                
                // Opponent stats
                VStack(alignment: .trailing, spacing: AppSpacing.small) {
                    Text("Opponent Performance")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let opponentId = opponent?.id,
                       let stats = match.statistics[opponentId] {
                        VStack(alignment: .trailing, spacing: 2) {
                            StatLine(label: "Eagles", value: "\(stats.eagles)", alignment: .trailing)
                            StatLine(label: "Birdies", value: "\(stats.birdies)", alignment: .trailing)
                            StatLine(label: "Pars", value: "\(stats.pars)", alignment: .trailing)
                            StatLine(label: "Bogeys", value: "\(stats.bogeys)", alignment: .trailing)
                            StatLine(label: "Double+", value: "\(stats.doubleBogeys + stats.tripleBogeyPlus)", alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Round Settings")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                InfoRow(label: "Concede Putt", value: match.settings.concedePutt ? "On" : "Off")
                InfoRow(label: "Putting Assist", value: match.settings.puttingAssist ? "On" : "Off")
                InfoRow(label: "Green Speed", value: match.settings.greenSpeed)
                InfoRow(label: "Wind Strength", value: match.settings.windStrength)
                InfoRow(label: "Mulligans", value: "\(match.settings.mulligans)")
                InfoRow(label: "Caddy Assist", value: match.settings.caddyAssist ? "On" : "Off")
                InfoRow(label: "Starting Hole", value: "\(match.settings.startingHole)")
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    private func formatScoreToPar(_ score: Int) -> String {
        if score == 0 { return "E" }
        return score > 0 ? "+\(score)" : "\(score)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct StatLine: View {
    let label: String
    let value: String
    let alignment: HorizontalAlignment
    
    init(label: String, value: String, alignment: HorizontalAlignment = .leading) {
        self.label = label
        self.value = value
        self.alignment = alignment
    }
    
    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer()
            }
            
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            
            if alignment == .leading {
                Spacer()
            }
        }
    }
}

// MARK: - Preview
struct MatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample match data for preview
        let sampleMatch = CompletedMatch(
            matchId: "sample",
            status: "completed",
            completedAt: Date(),
            startedAt: Date().addingTimeInterval(-7200),
            duration: 7200,
            course: CourseInfo(id: "1", name: "Pebble Beach Golf Links", city: "Pebble Beach", state: "CA"),
            tee: TeeInfo(name: "Championship", yardage: 6828, rating: 74.5, slope: 142, par: 72),
            players: [
                PlayerInfo(id: "user1", name: "John Doe", email: "john@example.com", elo: 1200),
                PlayerInfo(id: "user2", name: "Jane Smith", email: "jane@example.com", elo: 1250)
            ],
            scores: MatchScores(
                player: [4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4, 4],
                opponent: [5, 4, 4, 5, 3, 4, 6, 3, 5, 3, 4, 4, 5, 3, 4, 4, 5, 3]
            ),
            finalScores: ["user1": 72, "user2": 75],
            scoresToPar: ["user1": 0, "user2": 3],
            winnerId: "user1",
            winnerName: "John Doe",
            strokeDifference: 3,
            wasPlayoff: false,
            statistics: [
                "user1": PlayerMatchStats(holesPlayed: 18, totalStrokes: 72, eagles: 0, birdies: 2, pars: 14, bogeys: 2, doubleBogeys: 0, tripleBogeyPlus: 0, averageScore: 4.0),
                "user2": PlayerMatchStats(holesPlayed: 18, totalStrokes: 75, eagles: 0, birdies: 1, pars: 12, bogeys: 4, doubleBogeys: 1, tripleBogeyPlus: 0, averageScore: 4.17)
            ],
            settings: RoundSettingsData(concedePutt: true, puttingAssist: false, greenSpeed: "Medium", windStrength: "Light", mulligans: 1, caddyAssist: true, startingHole: 1),
            version: "2.0",
            platform: "iOS"
        )
        
        MatchDetailView(match: sampleMatch)
    }
} 
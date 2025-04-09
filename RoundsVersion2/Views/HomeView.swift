import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showingNewMatch = false
    @State private var showingMatchmaking = false
    @State private var selectedTab: Tab = .solo
    
    enum Tab {
        case solo, duos
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main background
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Blue background that extends to the top edge
                    Color(red: 0/255, green: 75/255, blue: 143/255) // #004B8F
                        .frame(height: 100) // Height for both status bar area and navigation bar
                        .ignoresSafeArea(edges: .top)
                        .overlay(
                            // Title centered in the visible portion of the blue area
                            Text("ROUNDS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 50) // Position below the status bar area
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    
                    // Main content - no scroll view to fit on one screen
                    VStack(spacing: 0) {
                        // Toggle buttons
                        toggleView
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Profile card with QR code
                        profileCardView
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Play round button
                        playRoundButton
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                    }
                    
                    Spacer() // Push everything up
                }
                .edgesIgnoringSafeArea(.top) // Ensure content goes to the top edge
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewMatch) {
                NavigationStack {
                    GolfCourseSelectorView(
                        viewModel: GolfCourseSelectorViewModel(),
                        onCourseAndTeeSelected: { course, tee, settings in
                            viewModel.createMatch(course: course, tee: tee, settings: settings)
                            showingNewMatch = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingMatchmaking) {
                MatchmakingView()
            }
            .onAppear {
                Task {
                    await viewModel.loadUserData()
                    await viewModel.loadActiveMatches()
                    await viewModel.loadPlayerStats()
                }
            }
        }
    }
    
    // Toggle between Solo and Duos
    private var toggleView: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(red: 234/255, green: 234/255, blue: 234/255)) // #EAEAEA
                .frame(height: 36)
            
            HStack(spacing: 0) {
                // Solo button
                Button(action: { selectedTab = .solo }) {
                    Text("Solo")
                        .font(.system(size: 14, weight: selectedTab == .solo ? .semibold : .medium))
                        .foregroundColor(selectedTab == .solo ? .white : Color(red: 85/255, green: 85/255, blue: 85/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            selectedTab == .solo ?
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                            : nil
                        )
                }
                
                // Duos button
                Button(action: { selectedTab = .duos }) {
                    Text("Duos")
                        .font(.system(size: 14, weight: selectedTab == .duos ? .semibold : .medium))
                        .foregroundColor(selectedTab == .duos ? .white : Color(red: 85/255, green: 85/255, blue: 85/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            selectedTab == .duos ?
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                            : nil
                        )
                }
            }
        }
        .frame(height: 36)
    }
    
    // Profile card with QR code
    private var profileCardView: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 0) {
                // QR code with profile image
                ZStack {
                    Image(systemName: "qrcode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .foregroundColor(.black)
                    
                    // Profile image overlay
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    // Actual profile image - now using the uploaded image if available
                    if let profileImage = mainViewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(mainViewModel.userProfile?.initials ?? "")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .padding(.top, 12)
                
                // Badge icon
                Image(systemName: "hexagon.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.purple)
                    .padding(.top, 8)
                
                // Username - Display actual username from mainViewModel
                Text(mainViewModel.userProfile?.fullName.uppercased() ?? "USERNAME")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.black)
                    .padding(.top, 4)
                
                // Handicap
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primaryNavy)
                    
                    Text("HI: \(String(format: "%.1f", Double(mainViewModel.userProfile?.elo ?? 0) / 100.0))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.top, 4)
                
                // Stats section
                VStack(spacing: 0) {
                    // First row of stats
                    HStack(spacing: 0) {
                        StatItem(title: "WINS", value: "\(viewModel.playerStats.wins)")
                        StatItem(title: "LOSSES", value: "\(viewModel.playerStats.losses)")
                        StatItem(title: "DRAWS", value: "0")
                        StatItem(title: "WIN %", value: viewModel.playerStats.winPercentage)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    
                    // Second row of stats
                    HStack(spacing: 0) {
                        StatItem(title: "BIRDIES", value: "\(viewModel.playerStats.birdies)")
                        StatItem(title: "PARS", value: "\(viewModel.playerStats.pars)")
                        StatItem(title: "BOGEYS", value: "\(viewModel.playerStats.bogeys)")
                        StatItem(title: "DOUBLES", value: "\(viewModel.playerStats.doubleBogeys)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 200/255, green: 200/255, blue: 200/255), lineWidth: 1)
                        .padding(.horizontal, 12)
                )
                .padding(.vertical, 8)
            }
        }
        .frame(height: 400) // Reduced from 509 to fit on screen
    }
    
    // Play round button
    private var playRoundButton: some View {
        Button(action: { 
            // Changed to trigger matchmaking instead of new match
            showingMatchmaking = true 
        }) {
            Text("PLAY ROUND")
                .font(.system(size: 14, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                )
        }
    }
}

// Battery view component
struct BatteryView: View {
    var body: some View {
        ZStack(alignment: .leading) {
            // Battery outline
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white, lineWidth: 1)
                .frame(width: 20, height: 10)
            
            // Battery fill
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .padding(.horizontal, 2)
                .frame(width: 16, height: 6)
            
            // Battery tip
            Rectangle()
                .fill(Color.white)
                .frame(width: 1, height: 4)
                .offset(x: 20 + 0.5)
        }
    }
}

// Stat item component
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundColor(Color(red: 119/255, green: 119/255, blue: 119/255)) // #777777
            
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(MainViewModel())
    }
} 
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MatchmakingView: View {
    @StateObject private var viewModel = MatchmakingViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main background
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Blue header background that extends to the top edge
                    Color(red: 0/255, green: 75/255, blue: 143/255) // #004B8F - matches HomeView
                        .frame(height: 100)
                        .ignoresSafeArea(edges: .top)
                        .overlay(
                            // Title centered in the visible portion of the blue area
                            Text(viewModel.matchState == .found ? "MATCH FOUND" : "MATCHMAKING")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 50) // Position below the status bar area
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    
                    // Main content area
                    VStack(spacing: 24) {
                        if viewModel.matchState == .searching {
                            // Searching Animation
                            searchingView
                        } else if viewModel.matchState == .found {
                            // Match Found UI - updated to match home design
                            matchFoundView
                        }
                        
                        // Cancel/Close button with consistent styling
                        Button {
                            if viewModel.matchState == .searching {
                                viewModel.cancelMatchmaking()
                            }
                            dismiss()
                        } label: {
                            Text(viewModel.matchState == .searching ? "CANCEL" : "CLOSE")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                                        .background(Color.white)
                                        .cornerRadius(22)
                                )
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 24)
                    
                    Spacer() // Push content to the top
                }
                .edgesIgnoringSafeArea(.top) // Ensure content goes to the top edge
                
                .onAppear {
                    viewModel.startMatchmaking()
                }
                .navigationDestination(isPresented: $viewModel.shouldNavigateToMatch) {
                    if let opponent = viewModel.opponent, let matchId = viewModel.matchId {
                        MatchView(matchId: matchId, opponent: opponent)
                            .environment(\.dismissToRoot, { 
                                viewModel.shouldNavigateToMatch = false
                                dismiss()
                            })
                    }
                }
            }
            .navigationBarHidden(true)
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
    
    // Match found view - redesigned to match home screen style
    private var matchFoundView: some View {
        VStack(spacing: 20) {
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.green)
            }
            .padding(.bottom, 4)
            
            if let opponent = viewModel.opponent {
                // Opponent profile card - styled like the home profile card
                ZStack {
                    // Card background with shadow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 16) {
                        // Profile image/initials
                        ZStack {
                            Circle()
                                .fill(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                                .frame(width: 80, height: 80)
                            
                            Text(opponent.initials)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Player name
                        Text(opponent.fullName.uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(Color(red: 0/255, green: 75/255, blue: 143/255)) // #004B8F
                        
                        // ELO/Handicap display
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            Text("HI: \(String(format: "%.1f", Double(opponent.elo) / 100.0))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        // Stats section
                        HStack(spacing: 24) {
                            statItem(title: "ELO", value: "\(opponent.elo)")
                            statItem(title: "RANK", value: "#\(opponent.elo / 10)")
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 200/255, green: 200/255, blue: 200/255), lineWidth: 1)
                        )
                        .padding(.top, 4)
                    }
                    .padding(24)
                }
                .padding(.horizontal)
            }
            
            // Accept match button
            Button {
                viewModel.acceptMatch()
            } label: {
                Text("ACCEPT MATCH")
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
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.vertical, 16)
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

struct MatchmakingView_Previews: PreviewProvider {
    static var previews: some View {
        MatchmakingView()
    }
} 
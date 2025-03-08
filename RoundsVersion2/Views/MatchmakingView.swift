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
                AppColors.backgroundWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if viewModel.matchState == .searching {
                        // Searching Animation
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(AppColors.subtleGray.opacity(0.2), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(AppColors.highlightBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(Angle(degrees: viewModel.rotation))
                                    .onAppear {
                                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                            viewModel.rotation = 360
                                        }
                                    }
                            }
                            
                            Text("Finding your opponent...")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primaryNavy)
                            
                            Text("ELO Range: \(viewModel.minElo) - \(viewModel.maxElo)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.subtleGray)
                                .padding(.top, 4)
                        }
                        .padding(30)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding()
                    } else if viewModel.matchState == .found {
                        // Match Found UI
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.green)
                            
                            Text("Match Found!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryNavy)
                            
                            if let opponent = viewModel.opponent {
                                PlayerProfileCard(profile: opponent)
                                    .padding(.vertical)
                            }
                            
                            Button {
                                viewModel.acceptMatch()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Accept Match")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .navyButton()
                        }
                        .padding(30)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding()
                    }
                    
                    Button {
                        if viewModel.matchState == .searching {
                            viewModel.cancelMatchmaking()
                        }
                        dismiss()
                    } label: {
                        Text(viewModel.matchState == .searching ? "Cancel" : "Close")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding()
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
        }
    }
}

#Preview {
    MatchmakingView()
} 
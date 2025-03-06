import SwiftUI
import FirebaseFirestore

struct MatchmakingView: View {
    @StateObject private var viewModel = MatchmakingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.matchState == .searching {
                // Searching Animation
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Finding your opponent...")
                        .font(.headline)
                    
                    Text("ELO Range: \(viewModel.minElo) - \(viewModel.maxElo)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if viewModel.matchState == .found {
                // Match Found UI
                VStack {
                    Text("Match Found!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let opponent = viewModel.opponent {
                        OpponentProfileCard(opponent: opponent)
                    }
                    
                    Button {
                        viewModel.acceptMatch()
                    } label: {
                        Text("Accept Match")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
            
            Button {
                if viewModel.matchState == .searching {
                    viewModel.cancelMatchmaking()
                }
                dismiss()
            } label: {
                Text(viewModel.matchState == .searching ? "Cancel" : "Close")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            viewModel.startMatchmaking()
        }
        .onChange(of: viewModel.shouldNavigateToMatch) { shouldNavigate in
            if shouldNavigate {
                // Navigate to MatchView
                // This will be implemented when we create the MatchView
            }
        }
    }
}

struct OpponentProfileCard: View {
    let opponent: UserProfile
    
    var body: some View {
        VStack(spacing: 10) {
            Text(opponent.initials)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.green)
                .clipShape(Circle())
            
            Text(opponent.fullName)
                .font(.headline)
            
            Text("ELO: \(opponent.elo)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    MatchmakingView()
} 
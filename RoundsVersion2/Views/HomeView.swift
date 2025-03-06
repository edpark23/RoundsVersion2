import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var isShowingMatchmaking = false
    @State private var activeMatch: (id: String, opponent: UserProfile)? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // User Stats Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(mainViewModel.userProfile?.initials ?? "??")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(mainViewModel.userProfile?.fullName ?? "Loading...")
                                .font(.headline)
                            Text("ELO: \(mainViewModel.userProfile?.elo ?? 1200)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // New Match Button
                Button {
                    isShowingMatchmaking = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Match")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $isShowingMatchmaking) {
                    MatchmakingView()
                }
                
                // Recent Matches List
                List {
                    ForEach(viewModel.recentMatches) { match in
                        MatchRow(match: match)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Home")
            .sheet(item: $activeMatch) { match in
                NavigationView {
                    MatchView(matchId: match.id, opponent: match.opponent)
                }
            }
        }
    }
}

// Make the tuple conform to Identifiable for sheet presentation
extension Optional: Identifiable where Wrapped == (id: String, opponent: UserProfile) {
    public var id: String? {
        self?.id
    }
}

struct MatchRow: View {
    let match: Match
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(match.opponentName)
                    .font(.headline)
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(match.result)
                .font(.headline)
                .foregroundColor(match.result == "Won" ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView()
        .environmentObject(MainViewModel())
} 
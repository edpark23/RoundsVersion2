import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var mainViewModel: MainViewModel
    
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
                    // TODO: Start new match
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
                
                // Recent Matches List
                List {
                    ForEach(viewModel.recentMatches) { match in
                        MatchRow(match: match)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Home")
        }
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
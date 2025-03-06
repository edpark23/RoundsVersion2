import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack {
                    Text(mainViewModel.userProfile?.initials ?? "??")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(Color.green)
                        .clipShape(Circle())
                    
                    Text(mainViewModel.userProfile?.fullName ?? "Loading...")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(mainViewModel.userProfile?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Stats Card
                VStack(spacing: 15) {
                    StatRow(title: "ELO Rating", value: "\(mainViewModel.userProfile?.elo ?? 1200)")
                    Divider()
                    StatRow(title: "Matches Played", value: "0") // TODO: Implement
                    Divider()
                    StatRow(title: "Win Rate", value: "0%") // TODO: Implement
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(MainViewModel())
} 
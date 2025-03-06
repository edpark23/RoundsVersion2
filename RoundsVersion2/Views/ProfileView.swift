import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    VStack(spacing: 15) {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                // Stats Section
                Section("Stats") {
                    StatRow(title: "ELO Rating", value: "\(mainViewModel.userProfile?.elo ?? 1200)")
                    StatRow(title: "Matches Played", value: "0") // TODO: Implement
                    StatRow(title: "Win Rate", value: "0%") // TODO: Implement
                }
                
                // Admin Section (only shown for admin users)
                if mainViewModel.userProfile?.isAdmin == true {
                    Section {
                        NavigationLink {
                            AdminView()
                        } label: {
                            Label("Admin Panel", systemImage: "gear")
                        }
                    } header: {
                        Text("Administration")
                    } footer: {
                        Text("Access to administrative functions")
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        Task {
                            await mainViewModel.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
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
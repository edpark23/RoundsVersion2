import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("Account")) {
                    NavigationLink {
                        Text("Edit Profile") // TODO: Implement profile editing
                    } label: {
                        Text("Edit Profile")
                    }
                    
                    NavigationLink {
                        Text("Change Password") // TODO: Implement password change
                    } label: {
                        Text("Change Password")
                    }
                }
                
                // Admin Section (only shown for admin users)
                if mainViewModel.userProfile?.isAdmin == true {
                    Section(header: Text("Administration"), footer: Text("Access to administrative functions")) {
                        NavigationLink {
                            AdminView()
                        } label: {
                            Label("Admin Panel", systemImage: "shield.fill")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MainViewModel())
} 
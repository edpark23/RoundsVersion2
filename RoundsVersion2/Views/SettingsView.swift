import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
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
                
                Section {
                    Button(role: .destructive) {
                        mainViewModel.signOut()
                    } label: {
                        Text("Sign Out")
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
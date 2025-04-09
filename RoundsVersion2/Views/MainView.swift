import SwiftUI
import FirebaseAuth

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tint(AppColors.primaryNavy)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tint(AppColors.primaryNavy)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tint(AppColors.primaryNavy)
        }
        .accentColor(AppColors.primaryNavy)
        .primaryBackground()
        .environmentObject(viewModel)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 
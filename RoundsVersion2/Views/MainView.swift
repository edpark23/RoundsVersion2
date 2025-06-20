import SwiftUI
import FirebaseAuth

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0
    @State private var tabOffset: CGFloat = 0

    @Namespace private var tabTransition
    
    var body: some View {
        ZStack {
            // Main content with modern transitions
            ZStack {
                // Home Tab
                HomeView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .scaleEffect(selectedTab == 0 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Rankings Tab
                RankingView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .scaleEffect(selectedTab == 1 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Social Tab
                SocialView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .scaleEffect(selectedTab == 2 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Tournaments Tab
                TournamentView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .scaleEffect(selectedTab == 3 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Settings Tab
                SettingsView()
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .scaleEffect(selectedTab == 4 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Modern Tab Bar
            VStack {
                Spacer()
                modernTabBar
            }
            

        }
        .background(AppColors.backgroundPrimary)
        .preferredColorScheme(.light)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Modern Tab Bar
    private var modernTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                tabBarItem(for: index)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectTab(index)
                    }
            }
        }
        .frame(height: 70)
        .background {
            // Modern tab bar background with blur effect
            ZStack {
                // Glass morphism background
                RoundedRectangle(cornerRadius: 25)
                    .fill(AppColors.surfacePrimary.opacity(0.9))
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                    }
                    .shadow(color: AppColors.borderMedium.opacity(0.3), radius: 20, x: 0, y: -5)
                

            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.bottom, AppSpacing.small)
    }
    
    private func tabBarItem(for index: Int) -> some View {
        let isSelected = selectedTab == index
        let (icon, title) = tabInfo(for: index)
        
        return VStack(spacing: 4) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: isSelected ? 24 : 20, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(
                    isSelected ? AppColors.primaryBlue : AppColors.textSecondary
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            // Title
            Text(title)
                .font(AppTypography.captionSmall)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.textSecondary)
                .opacity(isSelected ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 8)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    

    

    
    // MARK: - Helper Functions
    private func tabInfo(for index: Int) -> (String, String) {
        switch index {
        case 0: return ("house.fill", "Home")
        case 1: return ("chart.bar.fill", "Rankings")
        case 2: return ("person.2.fill", "Social")
        case 3: return ("trophy", "Tournaments")
        case 4: return ("gear", "Settings")
        default: return ("house.fill", "Home")
        }
    }
    
    private func selectTab(_ index: Int) {
        previousTab = selectedTab
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTab = index
        }
    }
    
    private func setupTabBarAppearance() {
        // Hide the default tab bar
        UITabBar.appearance().isHidden = true
        
        // Set overall app appearance
        UINavigationBar.appearance().isHidden = true
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 
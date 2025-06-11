import SwiftUI
import FirebaseAuth

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0
    @State private var tabOffset: CGFloat = 0
    @State private var showingFloatingActions = false
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
                
                // Ranking Tab
                RankingView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .scaleEffect(selectedTab == 1 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Profile Tab
                ProfileView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .scaleEffect(selectedTab == 2 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
                
                // Settings Tab
                SettingsView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .scaleEffect(selectedTab == 3 ? 1 : 0.95)
                    .animation(AppAnimations.smoothSpring, value: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Modern Tab Bar
            VStack {
                Spacer()
                modernTabBar
            }
            
            // Floating Action Button (only show on Home tab)
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .padding(.trailing, AppSpacing.large)
                    .padding(.bottom, 100) // Above tab bar
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
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
            ForEach(0..<4) { index in
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
                
                // Selection indicator
                HStack {
                    if selectedTab == 0 {
                        selectionIndicator
                            .matchedGeometryEffect(id: "tabSelection", in: tabTransition)
                        Spacer()
                        Spacer()
                        Spacer()
                    } else if selectedTab == 1 {
                        Spacer()
                        selectionIndicator
                            .matchedGeometryEffect(id: "tabSelection", in: tabTransition)
                        Spacer()
                        Spacer()
                    } else if selectedTab == 2 {
                        Spacer()
                        Spacer()
                        selectionIndicator
                            .matchedGeometryEffect(id: "tabSelection", in: tabTransition)
                        Spacer()
                    } else {
                        Spacer()
                        Spacer()
                        Spacer()
                        selectionIndicator
                            .matchedGeometryEffect(id: "tabSelection", in: tabTransition)
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
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
    
    private var selectionIndicator: some View {
        Capsule()
            .fill(AppColors.primaryBlue.opacity(0.15))
            .frame(width: 50, height: 35)
            .overlay {
                Capsule()
                    .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 1)
            }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showingFloatingActions.toggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.primaryBlue.opacity(0.4), radius: 15, x: 0, y: 5)
                
                Image(systemName: showingFloatingActions ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(showingFloatingActions ? 45 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingFloatingActions)
            }
        }
        .scaleEffect(showingFloatingActions ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingFloatingActions)
    }
    
    // MARK: - Helper Functions
    private func tabInfo(for index: Int) -> (String, String) {
        switch index {
        case 0: return ("house.fill", "Home")
        case 1: return ("chart.bar.fill", "Rankings")
        case 2: return ("person.circle.fill", "Profile")
        case 3: return ("gear", "Settings")
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
            showingFloatingActions = false
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
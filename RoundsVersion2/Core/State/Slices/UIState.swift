import Foundation
import SwiftUI

// MARK: - Centralized UI State
@Observable
class UIState {
    
    // MARK: - Navigation State
    var selectedTab: AppTab = .home
    var navigationPath = NavigationPath()
    var showingSettings = false
    var showingProfile = false
    
    // MARK: - Modal States
    var showingAddFriends = false
    var showingCreateTournament = false
    var showingScoreVerification = false
    var showingCourseSelector = false
    var showingImagePicker = false
    
    // MARK: - Sheet States
    var activeSheet: ActiveSheet?
    var activeFullScreenCover: ActiveFullScreenCover?
    
    // MARK: - Alert States
    var showingAlert = false
    var alertTitle = ""
    var alertMessage = ""
    var alertActions: [AlertAction] = []
    
    // MARK: - Loading Overlays
    var showingGlobalLoader = false
    var globalLoaderMessage = ""
    
    // MARK: - Keyboard and Focus
    var isKeyboardVisible = false
    var focusedField: FocusableField?
    
    // MARK: - Accessibility
    var isVoiceOverEnabled = false
    var preferredColorScheme: ColorScheme?
    var dynamicTypeSize: DynamicTypeSize = .medium
    
    // MARK: - Performance
    var reducedMotion = false
    var preferredFrameRate: Int = 60
    
    init() {
        setupAccessibilityObservers()
    }
    
    // MARK: - Navigation Actions
    @MainActor
    func selectTab(_ tab: AppTab) {
        if FeatureFlags.enablePerformanceMonitoring {
            PerformanceMonitor.measureSync("UIState.selectTab") {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
    }
    
    @MainActor
    func pushToNavigationPath<T: Hashable>(_ value: T) {
        navigationPath.append(value)
    }
    
    @MainActor
    func popNavigationPath() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    @MainActor
    func resetNavigationPath() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Modal Actions
    @MainActor
    func showSheet(_ sheet: ActiveSheet) {
        activeSheet = sheet
    }
    
    @MainActor
    func showFullScreenCover(_ cover: ActiveFullScreenCover) {
        activeFullScreenCover = cover
    }
    
    @MainActor
    func dismissSheet() {
        activeSheet = nil
    }
    
    @MainActor
    func dismissFullScreenCover() {
        activeFullScreenCover = nil
    }
    
    @MainActor
    func dismissAllModals() {
        activeSheet = nil
        activeFullScreenCover = nil
        showingSettings = false
        showingProfile = false
        showingAddFriends = false
        showingCreateTournament = false
        showingScoreVerification = false
        showingCourseSelector = false
        showingImagePicker = false
    }
    
    // MARK: - Alert Actions
    @MainActor
    func showAlert(title: String, message: String, actions: [AlertAction] = []) {
        alertTitle = title
        alertMessage = message
        alertActions = actions.isEmpty ? [AlertAction(title: "OK", style: .default, action: {})] : actions
        showingAlert = true
    }
    
    @MainActor
    func dismissAlert() {
        showingAlert = false
        alertTitle = ""
        alertMessage = ""
        alertActions.removeAll()
    }
    
    // MARK: - Loading Actions
    @MainActor
    func showGlobalLoader(message: String = "Loading...") {
        globalLoaderMessage = message
        showingGlobalLoader = true
    }
    
    @MainActor
    func hideGlobalLoader() {
        showingGlobalLoader = false
        globalLoaderMessage = ""
    }
    
    // MARK: - Focus Management
    @MainActor
    func setFocus(_ field: FocusableField?) {
        focusedField = field
    }
    
    @MainActor
    func clearFocus() {
        focusedField = nil
    }
    
    // MARK: - Accessibility Setup
    private func setupAccessibilityObservers() {
        // Monitor accessibility settings changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reducedMotion = UIAccessibility.isReduceMotionEnabled
        }
        
        // Initial values
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        reducedMotion = UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - Performance Optimization
    @MainActor
    func optimizeForLowPower() {
        if FeatureFlags.enablePerformanceMonitoring {
            preferredFrameRate = 30
            reducedMotion = true
        }
    }
    
    @MainActor
    func restoreNormalPerformance() {
        if FeatureFlags.enablePerformanceMonitoring {
            preferredFrameRate = 60
            reducedMotion = UIAccessibility.isReduceMotionEnabled
        }
    }
}

// MARK: - Supporting Enums and Structs
enum AppTab: String, CaseIterable {
    case home = "Home"
    case social = "Social"
    case tournaments = "Tournaments"
    case profile = "Profile"
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .social: return "person.2"
        case .tournaments: return "trophy"
        case .profile: return "person.circle"
        }
    }
}

enum ActiveSheet: Identifiable {
    case addFriends
    case createTournament
    case editProfile
    case settings
    case courseSelector
    
    var id: String {
        switch self {
        case .addFriends: return "addFriends"
        case .createTournament: return "createTournament"
        case .editProfile: return "editProfile"
        case .settings: return "settings"
        case .courseSelector: return "courseSelector"
        }
    }
}

enum ActiveFullScreenCover: Identifiable {
    case scoreVerification
    case cameraCapture
    case gameSetup
    
    var id: String {
        switch self {
        case .scoreVerification: return "scoreVerification"
        case .cameraCapture: return "cameraCapture"
        case .gameSetup: return "gameSetup"
        }
    }
}

struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let action: () -> Void
    
    init(title: String, style: UIAlertAction.Style = .default, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
}

enum FocusableField: Hashable {
    case searchBar
    case scoreInput(hole: Int)
    case tournamentTitle
    case tournamentDescription
    case chatMessage
    case profileDisplayName
} 
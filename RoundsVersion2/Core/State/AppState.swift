import Foundation
import SwiftUI
import Combine
import FirebaseAuth

// MARK: - Centralized App State with @Observable
@Observable
class AppState {
    
    // MARK: - Singleton
    static let shared = AppState()
    
    // MARK: - State Slices
    var authState = AuthState()
    var socialState = SocialState()
    var tournamentState = TournamentState()
    var gameState = GameState()
    var uiState = UIState()
    
    // MARK: - Global App State
    var isLoading = false
    var globalError: String?
    var networkStatus: NetworkStatus = .connected
    
    private init() {
        setupStateObservation()
    }
    
    // MARK: - State Management
    private func setupStateObservation() {
        // Monitor auth state changes
        authState.onUserChanged = { [weak self] user in
            Task { @MainActor in
                self?.handleUserChanged(user)
            }
        }
        
        // Monitor network changes
        Task {
            await startNetworkMonitoring()
        }
    }
    
    @MainActor
    private func handleUserChanged(_ user: FirebaseAuth.User?) {
        if user != nil {
            // User logged in - initialize other states
            socialState.initialize()
            tournamentState.initialize()
            gameState.initialize()
        } else {
            // User logged out - clear states
            socialState.reset()
            tournamentState.reset()
            gameState.reset()
        }
    }
    
    private func startNetworkMonitoring() async {
        // Simplified network monitoring
        // In production, use Network framework
        networkStatus = .connected
    }
    
    // MARK: - Global Actions
    func setGlobalLoading(_ loading: Bool) {
        Task { @MainActor in
            isLoading = loading
        }
    }
    
    func setGlobalError(_ error: String?) {
        Task { @MainActor in
            globalError = error
        }
    }
    
    func clearGlobalError() {
        Task { @MainActor in
            globalError = nil
        }
    }
    
    // MARK: - Performance Monitoring
    func performanceReport() -> String {
        return """
        📊 App State Performance:
        - Auth State: \(authState.isInitialized ? "✅" : "❌")
        - Social State: \(socialState.isInitialized ? "✅" : "❌")
        - Tournament State: \(tournamentState.isInitialized ? "✅" : "❌")
        - Network: \(networkStatus.rawValue)
        - Memory efficient: @Observable pattern
        """
    }
}

// MARK: - Network Status
enum NetworkStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case poor = "Poor Connection"
}

// MARK: - SwiftUI Environment Integration
struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState.shared
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
} 
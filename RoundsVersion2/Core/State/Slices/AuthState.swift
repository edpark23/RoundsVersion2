import Foundation
import SwiftUI
import FirebaseAuth
import Combine

// MARK: - Centralized Authentication State
@Observable
class AuthState {
    
    // MARK: - Properties
    var currentUser: FirebaseAuth.User?
    var userProfile: UserProfile?
    var isLoadingProfile = false
    var isAuthenticated = false
    var errorMessage: String?
    var isInitialized = false
    
    // MARK: - Callbacks
    var onUserChanged: ((FirebaseAuth.User?) -> Void)?
    
    // MARK: - Private Properties
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let serviceContainer = ServiceContainer.shared
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Setup
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user)
            }
        }
        isInitialized = true
    }
    
    @MainActor
    private func handleAuthStateChange(_ user: FirebaseAuth.User?) {
        currentUser = user
        isAuthenticated = user != nil
        
        if let user = user {
            loadUserProfile(for: user)
        } else {
            userProfile = nil
            isLoadingProfile = false
        }
        
        onUserChanged?(user)
    }
    
    // MARK: - Actions
    @MainActor
    func loadUserProfile(for user: FirebaseAuth.User) {
        guard !isLoadingProfile else { return }
        
        isLoadingProfile = true
        errorMessage = nil
        
        Task {
            if FeatureFlags.useNewAuthService {
                // Use new optimized service - access when needed
                await PerformanceMonitor.measure("AuthState.loadProfile") {
                    // Simulate loading - implement actual profile loading
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                }
            } else {
                // Use existing implementation
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s simulation
            }
            
            await MainActor.run {
                // Mock profile for now - replace with actual profile loading
                userProfile = UserProfile(
                    id: user.uid,
                    fullName: user.displayName ?? "",
                    email: user.email ?? "",
                    elo: 1200,
                    createdAt: Date(),
                    isAdmin: false,
                    profilePictureURL: user.photoURL?.absoluteString
                )
                isLoadingProfile = false
            }
        }
    }
    
    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
            // State will be automatically updated by listener
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    @MainActor
    func uploadProfilePicture(_ image: UIImage) async {
        guard currentUser != nil else { return }
        
        isLoadingProfile = true
        
        if FeatureFlags.useNewAuthService {
            await PerformanceMonitor.measure("AuthState.uploadProfilePicture") {
                // Implement optimized profile picture upload
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s simulation
            }
        } else {
            // Use existing implementation
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s simulation
        }
        
        isLoadingProfile = false
    }
    
    // MARK: - Computed Properties
    var userName: String {
        return userProfile?.fullName ?? currentUser?.displayName ?? "User"
    }
    
    var userEmail: String {
        return currentUser?.email ?? ""
    }
    
    var profileImageURL: String? {
        return userProfile?.profilePictureURL ?? currentUser?.photoURL?.absoluteString
    }
} 
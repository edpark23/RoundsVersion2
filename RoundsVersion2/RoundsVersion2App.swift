//
//  RoundsVersion2App.swift
//  RoundsVersion2
//
//  Created by Edward Park on 3/5/25.
//

import SwiftUI
import FirebaseCore
import UIKit
import Photos
import AVFoundation

// Helper class to request permissions
class PermissionsManager {
    static func requestPhotoAndCameraPermissions(completion: @escaping (Bool) -> Void) {
        let photoGroup = DispatchGroup()
        var photoGranted = false
        var cameraGranted = false
        
        // Request photo library permission
        photoGroup.enter()
        PHPhotoLibrary.requestAuthorization { status in
            photoGranted = (status == .authorized)
            photoGroup.leave()
        }
        
        // Request camera permission
        photoGroup.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraGranted = granted
            photoGroup.leave()
        }
        
        // Wait for both permissions to be processed
        photoGroup.notify(queue: .main) {
            completion(photoGranted && cameraGranted)
        }
    }
}

@main
struct RoundsVersion2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var mainViewModel = MainViewModel()
    @State private var showSplash = true
    @State private var isInitializing = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Splash screen - show immediately with highest priority
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(10)
                }
                
                // Main content
                Group {
                    if mainViewModel.currentUser != nil {
                        MainView()
                            .environmentObject(mainViewModel)
                    } else {
                        LoginView()
                    }
                }
                .opacity(showSplash ? 0 : 1)
            }
            .onAppear {
                // Show splash immediately
                showSplash = true
                
                // Initialize app with staggered initialization to prevent Firebase cascade
                Task(priority: .high) {
                    // Step 1: Wait for auth to stabilize first
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    
                    // Step 2: Initialize user state
                    await MainActor.run {
                        _ = mainViewModel.currentUser
                        isInitializing = false
                    }
                    
                    // Step 3: Wait before initializing other services
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                    
                    // Step 4: Phase 6 initialization (staggered)
                    await initializePhase6Staggered()
                    
                    // Step 5: Keep splash screen visible for minimum time
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s additional
                    
                    // Step 6: Hide splash with animation
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                }
                
                // Defer permission requests even further
                DispatchQueue.global(qos: .utility).async {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        PermissionsManager.requestPhotoAndCameraPermissions { granted in
                            if granted {
                                print("Photo and camera permissions granted")
                            } else {
                                print("Photo and/or camera permissions denied")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Staggered Phase 6 Initialization
    private func initializePhase6Staggered() async {
        // Initialize Modular Architecture first
        if FeatureFlags.useModularArchitecture {
            await initializeModularArchitecture()
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        }
        
        // Initialize Performance Dashboard second
        if FeatureFlags.usePerformanceDashboard {
            await MainActor.run {
                PerformanceDashboard.shared.startMonitoring()
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        }
        
        // Initialize Plugin System last
        if FeatureFlags.enablePluginSystem {
            await initializePluginSystem()
        }
        
        print("✅ Phase 6: Modular Architecture & Scalability initialized (staggered)")
    }
    
    private func initializeModularArchitecture() async {
        // Register core modules
        _ = await MainActor.run { ModuleManager.shared }
        
        // Example module registration would go here
        print("🏗️ Modular architecture initialized")
    }
    
    private func initializePluginSystem() async {
        _ = await MainActor.run { PluginManager.shared }
        
        // Core plugins are loaded automatically in PluginManager init
        print("🔌 Plugin system initialized")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase immediately on app launch
        FirebaseApp.configure()
        return true
    }
}

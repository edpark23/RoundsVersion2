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
                
                // Initialize app on a background thread
                Task(priority: .high) {
                    // Initialize user state
                    await MainActor.run {
                        _ = mainViewModel.currentUser
                        isInitializing = false
                    }
                    
                    // Keep splash screen visible for at least 1.8 seconds
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    
                    // Hide splash with animation
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                }
                
                // Defer permission requests
                DispatchQueue.global(qos: .utility).async {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase immediately on app launch
        FirebaseApp.configure()
        return true
    }
}

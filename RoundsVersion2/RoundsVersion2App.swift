//
//  RoundsVersion2App.swift
//  RoundsVersion2
//
//  Created by Edward Park on 3/5/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct RoundsVersion2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if mainViewModel.currentUser != nil {
                    MainView()
                        .environmentObject(mainViewModel)
                } else {
                    LoginView()
                }
            }
        }
    }
}

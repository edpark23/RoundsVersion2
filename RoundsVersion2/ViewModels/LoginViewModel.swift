import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var isAuthenticated = false
    
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            self.error = "Please fill in all fields"
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.isAuthenticated = true
            print("Successfully logged in user: \(result.user.uid)")
        } catch {
            self.error = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
    }
} 
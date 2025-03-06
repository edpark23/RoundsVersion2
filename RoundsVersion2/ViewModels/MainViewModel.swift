import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class MainViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
        if let user = Auth.auth().currentUser {
            fetchUserProfile(userId: user.uid)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let userId = user?.uid {
                self?.fetchUserProfile(userId: userId)
            } else {
                self?.userProfile = nil
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    private func fetchUserProfile(userId: String) {
        Task {
            do {
                let db = Firestore.firestore()
                let document = try await db.collection("users").document(userId).getDocument()
                if let data = document.data() {
                    self.userProfile = UserProfile(
                        id: userId,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        elo: data["elo"] as? Int ?? 1200,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
} 
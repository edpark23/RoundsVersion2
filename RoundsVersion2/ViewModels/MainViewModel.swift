import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var profileImage: UIImage?
    @Published var isUploading: Bool = false
    @Published var isLoadingProfile: Bool = false
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let storage = Storage.storage()
    private var hasInitializedProfile = false
    
    init() {
        // Only set up auth listener initially - defer other operations
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            self.currentUser = user
            
            // Only trigger profile fetch if we have a user
            if let userId = user?.uid {
                // Don't block the UI with this operation
                Task {
                    await self.fetchUserProfile(userId: userId)
                }
            } else {
                self.userProfile = nil
                self.profileImage = nil
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    private func fetchUserProfile(userId: String) async {
        // Set loading state
        self.isLoadingProfile = true
        
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                self.userProfile = UserProfile(
                    id: userId,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    elo: data["elo"] as? Int ?? 1200,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    isAdmin: data["isAdmin"] as? Bool ?? false,
                    profilePictureURL: data["profilePictureURL"] as? String
                )
                
                // Load profile image in background if URL exists
                if let profilePictureURL = self.userProfile?.profilePictureURL {
                    Task.detached(priority: .background) {
                        await self.loadProfileImage(from: profilePictureURL)
                    }
                }
                
                self.hasInitializedProfile = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        // Clear loading state
        self.isLoadingProfile = false
    }
    
    func uploadProfilePicture(image: UIImage) async {
        guard let userId = currentUser?.uid, let imageData = image.jpegData(compressionQuality: 0.7) else {
            self.errorMessage = "Failed to prepare image for upload"
            return
        }
        
        self.isUploading = true
        
        do {
            // Create a storage reference
            let storageRef = storage.reference().child("profile_pictures/\(userId).jpg")
            
            // Upload the image
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get the download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Update Firestore with the new profile picture URL
            let db = Firestore.firestore()
            await MainActor.run {
                db.collection("users").document(userId).updateData([
                    "profilePictureURL": downloadURL.absoluteString
                ])
            }
            
            // Update the local user profile
            if let updatedProfile = self.userProfile {
                self.userProfile = UserProfile(
                    id: updatedProfile.id,
                    fullName: updatedProfile.fullName,
                    email: updatedProfile.email,
                    elo: updatedProfile.elo,
                    createdAt: updatedProfile.createdAt,
                    isAdmin: updatedProfile.isAdmin,
                    profilePictureURL: downloadURL.absoluteString
                )
            }
            
            // Update the profile image
            self.profileImage = image
            self.isUploading = false
        } catch {
            self.errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
            self.isUploading = false
        }
    }
    
    private func loadProfileImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            // Use a more efficient way to load images with caching
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Update UI on main thread
            await MainActor.run {
                if let image = UIImage(data: data) {
                    self.profileImage = image
                }
            }
        } catch {
            print("Failed to load profile image: \(error.localizedDescription)")
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
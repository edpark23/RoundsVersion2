import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    VStack(spacing: 15) {
                        // Profile Picture with upload button
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage = mainViewModel.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Text(mainViewModel.userProfile?.initials ?? "??")
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 100)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            
                            // Camera button for photo upload
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                            .onChange(of: selectedItem) { oldValue, newValue in
                                if let newItem = newValue {
                                    loadTransferable(from: newItem)
                                }
                            }
                        }
                        
                        Text(mainViewModel.userProfile?.fullName ?? "Loading...")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(mainViewModel.userProfile?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if mainViewModel.isUploading {
                            ProgressView()
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                // Stats Section
                Section("Stats") {
                    StatRow(title: "ELO Rating", value: "\(mainViewModel.userProfile?.elo ?? 1200)")
                    StatRow(title: "Matches Played", value: "0") // TODO: Implement
                    StatRow(title: "Win Rate", value: "0%") // TODO: Implement
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        mainViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: .constant(mainViewModel.errorMessage != nil)) {
                Button("OK") {
                    mainViewModel.errorMessage = nil
                }
            } message: {
                Text(mainViewModel.errorMessage ?? "")
            }
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            Task { @MainActor in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        await mainViewModel.uploadProfilePicture(image: image)
                    }
                case .failure(let error):
                    mainViewModel.errorMessage = "Failed to load image: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(MainViewModel())
    }
} 
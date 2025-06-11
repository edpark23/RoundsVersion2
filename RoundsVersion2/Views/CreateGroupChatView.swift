import SwiftUI

struct CreateGroupChatView: View {
    @ObservedObject var viewModel: SocialViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.medium) {
                // Group name input
                groupNameSection
                
                // Friends selection
                friendsSelectionSection
                
                Spacer()
                
                // Create button
                createButton
            }
            .padding(.horizontal, AppSpacing.medium)
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    // MARK: - Group Name Section
    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Group Name")
                .font(AppTypography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            TextField("Enter group name", text: $viewModel.newGroupName)
                .font(AppTypography.bodyMedium)
                .padding(AppSpacing.medium)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.borderLight, lineWidth: 1)
                )
        }
        .padding(.top, AppSpacing.medium)
    }
    
    // MARK: - Friends Selection Section
    private var friendsSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Add Friends")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !viewModel.selectedFriendsForGroup.isEmpty {
                    Text("\(viewModel.selectedFriendsForGroup.count) selected")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primaryBlue)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if viewModel.hasFriends {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.small) {
                        ForEach(viewModel.socialService.friends) { friend in
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: viewModel.selectedFriendsForGroup.contains(friend.id)
                            ) {
                                viewModel.toggleFriendSelection(friendId: friend.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            } else {
                VStack(spacing: AppSpacing.medium) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("No friends available")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Add some friends first to create a group chat")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, AppSpacing.large)
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {
            isCreating = true
            Task {
                await viewModel.createGroupChat()
                isCreating = false
                if viewModel.error == nil {
                    dismiss()
                }
            }
        }) {
            HStack {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                }
                
                Text(isCreating ? "Creating..." : "Create Group")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .background(
                canCreateGroup ? AppColors.primaryBlue : AppColors.textTertiary
            )
            .cornerRadius(12)
        }
        .disabled(!canCreateGroup || isCreating)
        .padding(.bottom, AppSpacing.medium)
    }
    
    private var canCreateGroup: Bool {
        !viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.selectedFriendsForGroup.isEmpty
    }
}

// MARK: - Friend Selection Row
struct FriendSelectionRow: View {
    let friend: FriendUser
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.medium) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppColors.primaryBlue : AppColors.borderMedium,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryBlue)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Profile image
                ProfileImageView(
                    imageURL: friend.profileImageURL,
                    initials: friend.initials,
                    size: 40
                )
                
                // Friend info
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.fullName)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("@\(friend.username)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Online indicator
                if friend.isOnline {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(AppSpacing.medium)
            .background(
                isSelected ? AppColors.primaryBlue.opacity(0.05) : AppColors.surfacePrimary
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppColors.primaryBlue.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct CreateGroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupChatView(viewModel: SocialViewModel())
    }
}
#endif 
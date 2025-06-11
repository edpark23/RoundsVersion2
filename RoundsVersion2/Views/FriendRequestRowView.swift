import SwiftUI

struct FriendRequestRowView: View {
    let request: Friendship
    let onAction: (FriendRequestAction) -> Void
    @State private var isProcessing = false
    
    enum FriendRequestAction {
        case accept
        case decline
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // Profile placeholder (since we don't have full user info in Friendship)
            ProfileImageView(
                imageURL: nil,
                initials: "??", // Would be filled from user lookup
                size: 50
            )
            
            // Request info
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend Request")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Sent \(formatDate(request.createdAt))")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Requester ID: \(request.requesterId.prefix(8))...")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Action buttons
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: AppSpacing.small) {
                    // Decline button
                    Button(action: {
                        isProcessing = true
                        onAction(.decline)
                        resetProcessingState()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(AppColors.error)
                            .clipShape(Circle())
                    }
                    
                    // Accept button
                    Button(action: {
                        isProcessing = true
                        onAction(.accept)
                        resetProcessingState()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(AppColors.success)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func resetProcessingState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isProcessing = false
        }
    }
}

#if DEBUG
struct FriendRequestRowView_Previews: PreviewProvider {
    static var previews: some View {
        FriendRequestRowView(
            request: Friendship(
                requesterId: "user123",
                recipientId: "user456"
            )
        ) { action in
            print("Action: \(action)")
        }
        .padding()
    }
}
#endif 
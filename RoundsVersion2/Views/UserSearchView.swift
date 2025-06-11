import SwiftUI

struct UserSearchView: View {
    @ObservedObject var viewModel: SocialViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Search results
                if viewModel.isSearching {
                    loadingView
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    noResultsView
                } else if !viewModel.searchResults.isEmpty {
                    searchResultsList
                } else {
                    emptySearchView
                }
            }
            .navigationTitle("Find Friends")
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
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.title3)
            
            TextField("Search by name or username", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(AppTypography.bodyMedium)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.title3)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No users found")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Try searching with a different name or username")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.large)
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Empty Search View
    private var emptySearchView: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primaryBlue)
            
            Text("Find Friends")
                .font(AppTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Search for other golfers by name or username to add them as friends")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.large)
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(viewModel.searchResults) { user in
                    UserSearchResultRow(user: user) {
                        Task {
                            await viewModel.sendFriendRequest(to: user.id)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
        }
        .background(AppColors.backgroundPrimary)
    }
}

// MARK: - User Search Result Row
struct UserSearchResultRow: View {
    let user: UserSearchResult
    let onAddFriend: () -> Void
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // Profile image
            ProfileImageView(
                imageURL: user.profileImageURL,
                initials: user.initials,
                size: 50
            )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("@\(user.username)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.small) {
                    Text("Handicap: \(user.handicap, specifier: "%.1f")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(user.elo) ELO")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            
            Spacer()
            
            // Action button
            actionButton
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfacePrimary)
        .modernCard()
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch user.friendshipStatus {
        case .none:
            Button(action: {
                isLoading = true
                onAddFriend()
                // Reset loading state after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            .disabled(isLoading)
            
        case .pending:
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Pending")
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppColors.warning)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, 4)
            .background(AppColors.warning.opacity(0.1))
            .cornerRadius(8)
            
        case .accepted:
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "checkmark")
                    .font(.caption)
                Text("Friends")
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppColors.success)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, 4)
            .background(AppColors.success.opacity(0.1))
            .cornerRadius(8)
            
        case .blocked, .declined:
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "xmark")
                    .font(.caption)
                Text("Unavailable")
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, 4)
            .background(AppColors.textTertiary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#if DEBUG
struct UserSearchView_Previews: PreviewProvider {
    static var previews: some View {
        UserSearchView(viewModel: SocialViewModel())
    }
}
#endif 
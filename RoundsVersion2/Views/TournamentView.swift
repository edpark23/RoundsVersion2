import SwiftUI

struct TournamentView: View {
    @StateObject private var viewModel = TournamentViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    tournamentHeader
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.large) {
                            // Active Tournaments Section
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                HStack {
                                    Text("Active Tournaments")
                                        .font(AppTypography.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button("View All") {
                                        // Future: Show all active tournaments
                                    }
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.accentGold)
                                }
                                
                                ForEach(viewModel.tournaments.filter { $0.status == .active || $0.status == .registration }) { tournament in
                                    TournamentCard(
                                        tournament: tournament,
                                        onJoin: {
                                            viewModel.joinTournament(tournament)
                                        },
                                        onViewDetails: {
                                            // Future: Show tournament details
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.large)
                            
                            // Upcoming Tournaments Section
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                Text("Upcoming Tournaments")
                                    .font(AppTypography.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                ForEach(viewModel.tournaments.filter { $0.status == .upcoming }) { tournament in
                                    TournamentCard(
                                        tournament: tournament,
                                        onJoin: {
                                            viewModel.joinTournament(tournament)
                                        },
                                        onViewDetails: {
                                            // Future: Show tournament details
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.large)
                        }
                        .padding(.vertical, AppSpacing.large)
                    }
                    .refreshable {
                        viewModel.loadTournaments()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadTournaments()
        }
        .alert("Tournament Update", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showingCreateTournament) {
            CreateTournamentView(viewModel: viewModel)
        }
    }
    
    private var tournamentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accentGold)
                    
                    Text("Tournaments")
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Text("Compete in golf tournaments")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.showingCreateTournament = true
            }) {
                HStack(spacing: AppSpacing.xSmall) {
                    Image(systemName: "plus.circle.fill")
                    Text("Host")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(AppColors.accentGold)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.top, AppSpacing.medium)
    }
}

struct CreateTournamentView: View {
    @ObservedObject var viewModel: TournamentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType = TournamentType.daily
    @State private var entryFee = 5.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Tournament Details")
                        .font(AppTypography.titleMedium)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Title")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        
                        TextField("Enter tournament title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Description")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        
                        TextField("Enter description", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Type")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        
                        Picker("Tournament Type", selection: $selectedType) {
                            ForEach(TournamentType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Entry Fee")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("$")
                            TextField("0.00", value: $entryFee, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(AppSpacing.large)
                
                Spacer()
                
                Button {
                    // TODO: Implement tournament creation
                    dismiss()
                } label: {
                    Text("Create Tournament")
                        .font(AppTypography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGold)
                        .cornerRadius(12)
                }
                .padding(AppSpacing.large)
                .disabled(title.isEmpty)
            }
            .navigationTitle("Create Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TournamentView()
} 
import SwiftUI

struct PlayerProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 8) {
            Text(profile.initials)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(AppColors.primaryNavy)
                .clipShape(Circle())
            
            Text(profile.fullName)
                .font(.headline)
                .foregroundColor(AppColors.primaryNavy)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(Color.yellow)
                
                Text("ELO \(profile.elo)")
                    .font(.caption)
                    .foregroundColor(AppColors.highlightBlue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Extension to apply rounded corners to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
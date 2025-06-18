import SwiftUI

// MARK: - Modern Typography System
struct Typography {
    // MARK: - Font Styles
    struct Fonts {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
}

// MARK: - Modern Button Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Typography.Fonts.headline)
                    .foregroundColor(AppColors.textWhite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
        .primaryButton()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Typography.Fonts.headline)
                    .foregroundColor(AppColors.primaryGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
        .secondaryButton()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct TertiaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Typography.Fonts.headline)
                    .foregroundColor(AppColors.primaryGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
        .lightBorder()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Input Components
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @State private var isFocused = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Typography.Fonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(Typography.Fonts.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? AppColors.primaryGreen : AppColors.borderLight, lineWidth: isFocused ? 2 : 1)
                )
                .onTapGesture {
                    isFocused = true
                }
        }
    }
}

// MARK: - Modern Card Components
struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .modernCard()
    }
}

struct ElevatedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .elevatedCard()
    }
}

struct FeaturedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .featuredCard()
    }
}

// MARK: - Status Components
struct StatusBadge: View {
    let text: String
    let type: StatusType
    
    enum StatusType {
        case success, warning, error, info, neutral
        
        var backgroundColor: Color {
            switch self {
            case .success: return AppColors.success
            case .warning: return AppColors.warning
            case .error: return AppColors.error
            case .info: return AppColors.info
            case .neutral: return AppColors.textTertiary
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(Typography.Fonts.caption1)
            .foregroundColor(AppColors.textWhite)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(type.backgroundColor)
            .cornerRadius(8)
    }
}

struct LoadingSpinner: View {
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: "arrow.2.circlepath")
            .font(.title2)
            .foregroundColor(AppColors.primaryGreen)
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Enhanced Player Profile Card
struct PlayerProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        ModernCard {
            VStack(spacing: 12) {
                // Profile Image/Initials
                Text(profile.initials)
                    .font(Typography.Fonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textWhite)
                    .frame(width: 80, height: 80)
                    .background(AppColors.gradientPrimary)
                    .clipShape(Circle())
                    .shadow(color: AppColors.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Name
                Text(profile.fullName)
                    .font(Typography.Fonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // ELO Rating
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(Typography.Fonts.caption1)
                        .foregroundColor(AppColors.accentGold)
                    
                    Text("ELO \(profile.elo)")
                        .font(Typography.Fonts.callout)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.lightGreen)
                .cornerRadius(20)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, message: String, systemImage: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.Fonts.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(Typography.Fonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

// MARK: - Corner Radius Extension
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

// MARK: - Reusable Header Component
struct UniformHeader: View {
    let title: String
    let onBackTapped: () -> Void
    let onMenuTapped: (() -> Void)?
    
    init(title: String, onBackTapped: @escaping () -> Void, onMenuTapped: (() -> Void)? = nil) {
        self.title = title
        self.onBackTapped = onBackTapped
        self.onMenuTapped = onMenuTapped
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.0, green: 75/255, blue: 143/255).ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                // Status bar space - increased for better positioning
                Color.clear.frame(height: 50)
                
                // Navigation bar
                HStack {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                        .tracking(0.5)
                    
                    Spacer()
                    
                    if let onMenuTapped = onMenuTapped {
                        Button(action: onMenuTapped) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    } else {
                        // Invisible spacer to keep text centered
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.clear)
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 106)
    }
} 
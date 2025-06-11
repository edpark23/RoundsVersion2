import SwiftUI

// MARK: - Modern Blue-Inspired Color System
struct AppColors {
    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 13/255, green: 71/255, blue: 161/255)        // Deep Blue #0D47A1
    static let secondaryBlue = Color(red: 25/255, green: 118/255, blue: 210/255)     // Bright Blue #1976D2
    static let accentNavy = Color(red: 21/255, green: 101/255, blue: 192/255)        // Royal Blue #1565C0
    
    // MARK: - Support Colors
    static let lightBlue = Color(red: 187/255, green: 222/255, blue: 251/255)        // Light Blue #BBDEFB
    static let deepNavy = Color(red: 13/255, green: 27/255, blue: 42/255)            // Deep Navy #0D1B2A
    static let charcoal = Color(red: 33/255, green: 37/255, blue: 41/255)            // Charcoal #212529
    
    // MARK: - Background Colors
    static let backgroundPrimary = Color(red: 248/255, green: 249/255, blue: 250/255) // Soft White #F8F9FA
    static let backgroundSecondary = Color(red: 241/255, green: 245/255, blue: 249/255) // Light Gray #F1F5F9
    static let surfacePrimary = Color.white                                           // Pure White
    static let cardBackground = Color(red: 255/255, green: 255/255, blue: 255/255)   // Card White
    static let overlayBackground = Color.black.opacity(0.6)                          // Modal Overlay
    
    // MARK: - Text Colors
    static let textPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)         // Dark Blue #0F172A
    static let textSecondary = Color(red: 100/255, green: 116/255, blue: 139/255)    // Medium Gray #64748B
    static let textTertiary = Color(red: 148/255, green: 163/255, blue: 184/255)     // Light Gray #94A3B8
    
    // MARK: - Border Colors  
    static let borderLight = Color(red: 229/255, green: 231/255, blue: 235/255)      // Light Border #E5E7EB
    static let borderMedium = Color(red: 209/255, green: 213/255, blue: 219/255)     // Medium Border #D1D5DB
    static let borderDark = Color(red: 156/255, green: 163/255, blue: 175/255)       // Dark Border #9CA3AF
    static let border = borderLight                                                   // Default Border
    
    // MARK: - Dark Mode Colors
    static let backgroundDark = Color(red: 17/255, green: 24/255, blue: 39/255)      // Dark Background #111827
    static let backgroundLight = backgroundPrimary                                    // Light Background
    static let surfaceDark = Color(red: 31/255, green: 41/255, blue: 55/255)         // Dark Surface #1F2937
    static let surfaceLight = surfacePrimary                                          // Light Surface
    static let textOnDark = Color(red: 248/255, green: 250/255, blue: 252/255)       // Light Text for Dark Mode #F8FAFC
    
    // MARK: - Status Colors
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)            // Success Green #22C55E
    static let warning = Color(red: 251/255, green: 191/255, blue: 36/255)           // Warning Yellow #FBBF24
    static let error = Color(red: 239/255, green: 68/255, blue: 68/255)              // Error Red #EF4444
    static let info = Color(red: 59/255, green: 130/255, blue: 246/255)              // Info Blue #3B82F6
    
    // MARK: - White Text Colors for Dark Backgrounds
    static let textWhite = Color.white                                                // White text for dark backgrounds
    
    // MARK: - Gradient Colors
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [primaryBlue, secondaryBlue]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Additional Colors Referenced in Components
    static let accentGold = accentNavy                                               // Accent color (mapped to navy)
    
    // MARK: - Legacy Support for Backward Compatibility
    static let primaryGreen = primaryBlue
    static let secondaryGreen = secondaryBlue
    static let accentGreen = accentNavy
    static let lightGreen = lightBlue
    static let championshipGold = accentNavy
    static let forestGreen = primaryBlue
    static let freshGreen = secondaryBlue
    static let primaryNavy = primaryBlue
    static let secondaryNavy = secondaryBlue
    static let highlightBlue = accentNavy
    static let offWhite = backgroundSecondary
    static let pureWhite = backgroundPrimary
    static let mediumGray = textSecondary
    
    // MARK: - Additional Missing Colors
    static let backgroundWhite = Color.white                                          // Pure white background
    static let subtleGray = Color(red: 156/255, green: 163/255, blue: 175/255)       // Subtle gray #9CA3AF
}

// MARK: - Dark Mode Support
extension AppColors {
    static func dynamicBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }
    
    static func dynamicSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfaceDark : surfaceLight
    }
    
    static func dynamicText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textOnDark : textPrimary
    }
    
    static func dynamicBorder(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? borderDark : border
    }
}

// MARK: - Typography System
struct AppTypography {
    // Display styles
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .default)
    
    // Title styles
    static let titleLarge = Font.system(size: 22, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)
    
    // Body styles
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Caption styles
    static let captionLarge = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    static let caption = captionMedium // Default caption style
    
    // Label styles
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Font Size Values (for backward compatibility)
    static let headline: CGFloat = 18
    static let body: CGFloat = 16  
    static let caption1: CGFloat = 12
    
    // MARK: - Font Weight Values (for backward compatibility)
    static let semibold = Font.Weight.semibold
    static let medium = Font.Weight.medium
    static let regular = Font.Weight.regular
    static let bold = Font.Weight.bold
}

// MARK: - Modern UI Components
extension View {
    // MARK: - Button Styles
    func primaryButton() -> some View {
        self
            .font(.system(size: AppTypography.headline, weight: AppTypography.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.primaryBlue)
            .cornerRadius(12)
            .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    func secondaryButton() -> some View {
        self
            .font(.system(size: AppTypography.headline, weight: AppTypography.medium))
            .foregroundColor(AppColors.primaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.lightBlue.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 1)
            )
    }
    
    func tertiaryButton() -> some View {
        self
            .font(.system(size: AppTypography.body, weight: AppTypography.medium))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(8)
    }
    
    // MARK: - Card Styles
    func modernCard() -> some View {
        self
            .background(AppColors.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: AppColors.borderMedium.opacity(0.2), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Text Field Styles
    func modernTextField() -> some View {
        self
            .font(.system(size: AppTypography.body))
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
    }
    
    // MARK: - Status Badge
    func statusBadge(color: Color) -> some View {
        self
            .font(.system(size: AppTypography.caption1, weight: AppTypography.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Modern View Extensions
extension View {
    // MARK: - Background Styles
    func primaryBackground() -> some View {
        self.background(AppColors.backgroundPrimary)
    }
    
    func cardBackground() -> some View {
        self.background(AppColors.cardBackground)
    }
    
    func overlayBackground() -> some View {
        self.background(AppColors.overlayBackground)
    }
    
    // MARK: - Border Styles
    func lightBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
    }
    
    func mediumBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderMedium, lineWidth: 1.5)
        )
    }
    
    func focusedBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primaryBlue, lineWidth: 2)
        )
    }
    
    // Legacy card style for backward compatibility
    func cardStyle() -> some View {
        self.modernCard()
    }
    
    // MARK: - Additional Card Styles
    func elevatedCard() -> some View {
        self
            .background(AppColors.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: AppColors.borderMedium.opacity(0.3), radius: 12, x: 0, y: 4)
    }
    
    func featuredCard() -> some View {
        self
            .background(AppColors.surfacePrimary)
            .cornerRadius(20)
            .shadow(color: AppColors.primaryBlue.opacity(0.2), radius: 16, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.primaryBlue.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Convenient Color Extensions
extension AppColors {
    // App-level semantic colors for easy use throughout the app
    static let appPrimary = AppColors.primaryBlue
    static let appSecondary = AppColors.secondaryBlue
    static let appAccent = AppColors.accentNavy
    static let appBackground = AppColors.backgroundPrimary
    static let appSurface = AppColors.surfacePrimary
    static let appText = AppColors.textPrimary
    static let appTextSecondary = AppColors.textSecondary
    static let appBorder = AppColors.borderLight
    static let appShadow = AppColors.borderMedium
    static let appSuccess = AppColors.success
    static let appWarning = AppColors.warning
    static let appError = AppColors.error
}

// MARK: - Spacing System
struct AppSpacing {
    // Basic spacing units
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let xxLarge: CGFloat = 48
    
    // Component specific spacing
    static let buttonPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let listItemSpacing: CGFloat = 12
}

// MARK: - Shadow System
struct AppShadows {
    static let small = Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let medium = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let large = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let extraLarge = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Corner Radius System  
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let circle: CGFloat = 1000 // Very large number for circular radius
}

// MARK: - Animation System for Phase 3
struct AppAnimations {
    // Spring animations
    static let quickSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let smoothSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let bounceSpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // Easing animations
    static let quickEase = Animation.easeInOut(duration: 0.3)
    static let smoothEase = Animation.easeInOut(duration: 0.5)
    static let fastEase = Animation.easeInOut(duration: 0.2)
    
    // Timing functions
    static let buttonPress = Animation.easeInOut(duration: 0.1)
    static let cardFlip = Animation.easeInOut(duration: 0.4)
    static let slideTransition = Animation.spring(response: 0.4, dampingFraction: 0.9)
}

// MARK: - Enhanced View Modifiers for Phase 3 Navigation

extension View {
    // MARK: - Modern Navigation Modifiers
    func modernNavigationBar(title: String = "", backgroundColor: Color = AppColors.surfacePrimary) -> some View {
        self.modifier(ModernNavigationBarModifier(title: title, backgroundColor: backgroundColor))
    }
    
    func interactiveNavigation() -> some View {
        self.modifier(InteractiveNavigationModifier())
    }
    
    func gestureNavigation() -> some View {
        self.modifier(GestureNavigationModifier())
    }
    
    // MARK: - Enhanced Modal Presentations
    func modernSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(ModernSheetModifier(isPresented: isPresented, content: content))
    }
    
    func modernFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(ModernFullScreenModifier(isPresented: isPresented, content: content))
    }
    
    // MARK: - Interactive Gestures
    func swipeGestures(
        onSwipeLeft: @escaping () -> Void = {},
        onSwipeRight: @escaping () -> Void = {},
        onSwipeUp: @escaping () -> Void = {},
        onSwipeDown: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(SwipeGestureModifier(
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown
        ))
    }
    
    func longPressGesture(
        duration: Double = 0.5,
        onLongPress: @escaping () -> Void
    ) -> some View {
        self.modifier(LongPressGestureModifier(duration: duration, onLongPress: onLongPress))
    }
    
    // MARK: - Enhanced Button Interactions
    func interactiveButton() -> some View {
        self.modifier(InteractiveButtonModifier())
    }
    
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.modifier(HapticFeedbackModifier(style: style))
    }
    
    // MARK: - Transition Effects
    func slideTransition(edge: Edge = .leading) -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .leading ? .trailing : .leading).combined(with: .opacity)
        ))
    }
    
    func scaleTransition() -> some View {
        self.transition(.scale.combined(with: .opacity))
    }
    
    func cardStackTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .scale(scale: 1.1)).combined(with: .opacity)
        ))
    }
}

// MARK: - Navigation Modifiers Implementation

struct ModernNavigationBarModifier: ViewModifier {
    let title: String
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(AppTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct InteractiveNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(.navigationSlide)
            .animation(AppAnimations.slideTransition, value: UUID())
    }
}

struct GestureNavigationModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 && abs(value.translation.height) < 50 {
                            dismiss()
                        }
                    }
            )
    }
}

struct SwipeGestureModifier: ViewModifier {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if horizontalAmount < -50 {
                                onSwipeLeft()
                            } else if horizontalAmount > 50 {
                                onSwipeRight()
                            }
                        } else {
                            if verticalAmount < -50 {
                                onSwipeUp()
                            } else if verticalAmount > 50 {
                                onSwipeDown()
                            }
                        }
                    }
            )
    }
}

struct LongPressGestureModifier: ViewModifier {
    let duration: Double
    let onLongPress: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: duration) {
                onLongPress()
            }
    }
}

struct InteractiveButtonModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(AppAnimations.buttonPress, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }) {}
    }
}

struct HapticFeedbackModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.impactOccurred()
            }
    }
}

struct ModernSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                self.content()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
    }
}

struct ModernFullScreenModifier<FullScreenContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> FullScreenContent
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                self.content()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
    }
}

// MARK: - Navigation Transition Support
extension AnyTransition {
    static var navigationSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var modalSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

// MARK: - Phase 4 Live Match UI Components

struct LiveMatchCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.medium)
            .background(AppColors.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primaryBlue.opacity(0.3), AppColors.accentGold.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct LiveIndicator: ViewModifier {
    @State private var pulse = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.7 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulse
                    )
                    .onAppear {
                        pulse = true
                    },
                alignment: .topTrailing
            )
    }
}

struct ScoreColorBackground: ViewModifier {
    let score: Int
    let par: Int
    
    private var backgroundColor: Color {
        switch score - par {
        case ..<(-1): return AppColors.success // Eagle or better
        case -1: return AppColors.birdieGreen // Birdie
        case 0: return AppColors.primaryBlue // Par
        case 1: return AppColors.warning // Bogey
        default: return AppColors.error // Double bogey or worse
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct HoleTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.05 : 1.0)
            .opacity(isActive ? 1.0 : 0.7)
            .animation(AppAnimations.quickSpring, value: isActive)
    }
}

// MARK: - Phase 4 Animation Presets

extension AppAnimations {
    static let holeChange = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let scoreEntry = Animation.spring(response: 0.3, dampingFraction: 0.9)
    static let leaderboardUpdate = Animation.easeInOut(duration: 0.5)
    static let liveUpdate = Animation.easeInOut(duration: 0.3)
}

// MARK: - Phase 4 Colors

extension AppColors {
    static let liveGreen = Color(red: 0.2, green: 0.8, blue: 0.4) // For live indicators
    static let scoreBackground = Color(red: 0.95, green: 0.95, blue: 0.97) // Score card background
    static let holeActive = Color(red: 0.0, green: 0.47, blue: 0.84) // Active hole highlight
    static let birdieGreen = Color(red: 0.13, green: 0.7, blue: 0.67) // Birdie color
}

// MARK: - Phase 4 View Extensions

extension View {
    func liveMatchCard() -> some View {
        modifier(LiveMatchCard())
    }
    
    func liveIndicator() -> some View {
        modifier(LiveIndicator())
    }
    
    func scoreBackground(score: Int, par: Int) -> some View {
        modifier(ScoreColorBackground(score: score, par: par))
    }
    
    func holeTransition(isActive: Bool) -> some View {
        modifier(HoleTransition(isActive: isActive))
    }
    
    func pulseOnUpdate<T: Equatable>(_ value: T) -> some View {
        self
            .scaleEffect(1.0)
            .animation(AppAnimations.liveUpdate, value: value)
            .onChange(of: value) { _, _ in
                withAnimation(AppAnimations.quickSpring) {
                    // Trigger pulse animation
                }
            }
    }
} 
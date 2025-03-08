import SwiftUI

struct AppColors {
    static let primaryNavy = Color(red: 28/255, green: 45/255, blue: 65/255)  // Deep navy
    static let secondaryNavy = Color(red: 39/255, green: 60/255, blue: 117/255)  // Lighter navy for accents
    static let highlightBlue = Color(red: 72/255, green: 147/255, blue: 255/255)  // Bright blue for highlights
    static let backgroundWhite = Color(red: 248/255, green: 250/255, blue: 252/255)  // Off-white for backgrounds
    static let textWhite = Color.white  // Pure white for text on dark backgrounds
    static let subtleGray = Color(red: 156/255, green: 163/255, blue: 175/255)  // Subtle gray for secondary text
}

extension View {
    func primaryBackground() -> some View {
        self.background(AppColors.backgroundWhite)
    }
    
    func navyButton() -> some View {
        self.foregroundColor(AppColors.textWhite)
            .background(AppColors.primaryNavy)
            .cornerRadius(10)
    }
    
    func cardStyle() -> some View {
        self.background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
} 
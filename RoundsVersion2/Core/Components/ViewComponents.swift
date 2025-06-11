import SwiftUI
import UIKit

// MARK: - Component-Based View Architecture
// High-performance, reusable UI components

// MARK: - Performance-Optimized Cards
struct OptimizedCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    @State private var isVisible = false
    
    enum CardStyle {
        case compact
        case standard
        case featured
        case stat
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            case .standard: return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            case .featured: return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            case .stat: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 8
            case .standard: return 12
            case .featured: return 16
            case .stat: return 10
            }
        }
    }
    
    init(style: CardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        if FeatureFlags.useComponentViews {
            content
                .padding(style.padding)
                .background(AppColors.surfacePrimary)
                .cornerRadius(style.cornerRadius)
                .shadow(color: AppColors.borderMedium.opacity(0.15), radius: 4, x: 0, y: 2)
                .scaleEffect(isVisible ? 1.0 : 0.95)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
                .onAppear { isVisible = true }
                .drawingGroup() // Metal optimization
        } else {
            content
                .modernCard()
        }
    }
}

// MARK: - Performance-Optimized Lists
struct OptimizedLazyList<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemBuilder: (Item) -> ItemView
    let estimatedItemHeight: CGFloat
    @State private var visibleRange: Range<Int> = 0..<10
    
    init(items: [Item], estimatedItemHeight: CGFloat = 80, @ViewBuilder itemBuilder: @escaping (Item) -> ItemView) {
        self.items = items
        self.estimatedItemHeight = estimatedItemHeight
        self.itemBuilder = itemBuilder
    }
    
    var body: some View {
        if FeatureFlags.useViewRecycling && items.count > 20 {
            // Use optimized recycling for large lists
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(items[visibleRange], id: \.id) { item in
                    itemBuilder(item)
                        .frame(minHeight: estimatedItemHeight)
                        .id(item.id)
                }
            }
            .onPreferenceChange(ViewOffsetKey.self) { offset in
                updateVisibleRange(offset: offset)
            }
        } else {
            // Standard implementation for smaller lists
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(items, id: \.id, content: itemBuilder)
            }
        }
    }
    
    private func updateVisibleRange(offset: CGFloat) {
        let screenHeight = UIScreen.main.bounds.height
        let startIndex = max(0, Int(offset / estimatedItemHeight) - 5)
        let endIndex = min(items.count, startIndex + Int(screenHeight / estimatedItemHeight) + 10)
        visibleRange = startIndex..<endIndex
    }
}

// MARK: - Smart Image Component
struct SmartImageView: View {
    let url: String?
    let placeholder: String
    let size: CGSize
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
                    .background(AppColors.backgroundSecondary)
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: min(size.width, size.height) * 0.4))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: size.width, height: size.height)
                    .background(AppColors.backgroundSecondary)
            }
        }
        .cornerRadius(8)
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = url, !urlString.isEmpty else { return }
        
        isLoading = true
        
        // Use the advanced image cache if available
        if FeatureFlags.useAdvancedImageCache {
            let cachedImage = await ServiceContainer.shared.advancedImageCache().cachedImage(for: urlString)
            await MainActor.run {
                loadedImage = cachedImage
                isLoading = false
            }
        } else if FeatureFlags.useNewImageCache {
            let cachedImage = await ServiceContainer.shared.imageCache().cachedImage(for: urlString)
            await MainActor.run {
                loadedImage = cachedImage
                isLoading = false
            }
        } else {
            // Fallback to standard loading
            guard let imageURL = URL(string: urlString) else {
                isLoading = false
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                await MainActor.run {
                    loadedImage = UIImage(data: data)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Optimized Button Components
struct PerformanceButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppColors.primaryBlue
            case .secondary: return AppColors.lightBlue.opacity(0.2)
            case .tertiary: return Color.clear
            case .destructive: return AppColors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary, .tertiary: return AppColors.primaryBlue
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .background(style.backgroundColor)
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {}
        .drawingGroup() // Metal optimization
    }
}

// MARK: - High-Performance Stats Grid
struct StatsGrid: View {
    let stats: [StatItem]
    let columns: Int
    
    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
    }
    
    var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible()), count: columns)
        
        LazyVGrid(columns: gridColumns, spacing: AppSpacing.medium) {
            ForEach(stats) { stat in
                OptimizedCard(style: .stat) {
                    VStack(spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: stat.icon)
                                .foregroundColor(stat.color)
                                .font(.title3)
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.value)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(stat.title)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Performance Helper Views
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Component Performance Monitor
class ComponentPerformanceMonitor: ObservableObject {
    @Published var renderCount = 0
    @Published var lastRenderTime = Date()
    
    func recordRender() {
        renderCount += 1
        lastRenderTime = Date()
    }
}

// MARK: - Performance Environment
struct PerformanceEnvironment {
    static let monitor = ComponentPerformanceMonitor()
} 
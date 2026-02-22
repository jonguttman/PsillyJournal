import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Typography

enum AppFont {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let captionSecondary = Font.caption2

    static func system(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Colors

enum AppColor {
    static let primary = Color("AccentColor")
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let separator = Color(.separator)

    // Metric colors
    static let mood = Color.blue
    static let energy = Color.orange
    static let stress = Color.red
    static let sleep = Color.purple

    // Semantic
    static let safe = Color.green
    static let warning = Color.yellow
    static let danger = Color.red
    static let crisisBackground = Color.red.opacity(0.1)

    // Lens colors
    static let groundingLens = Color.teal
    static let meaningLens = Color.indigo
    static let integrationLens = Color.mint
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .background(AppColor.secondaryBackground)
            .cornerRadius(CornerRadius.md)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

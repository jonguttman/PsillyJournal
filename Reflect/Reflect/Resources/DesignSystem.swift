import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

// MARK: - Typography (Quiet Depth)
// Serif display + system body. Literary, contemplative feel.

enum AppFont {
    // Display & Headings — New York serif
    static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let title = Font.system(.title2, design: .serif).weight(.semibold)
    static let headline = Font.system(.headline, design: .serif).weight(.semibold)

    // Body & UI — System default (SF Pro)
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let captionSecondary = Font.caption2

    // Monospaced digits for metrics
    static let metricLarge = Font.system(size: 28, weight: .semibold, design: .serif)
    static let metricSmall = Font.system(size: 15, weight: .medium, design: .serif)

    static func system(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Colors (Quiet Depth)
// Warm amber/sage palette — leather-journal warmth

enum AppColor {
    // Core palette — adaptive for light/dark
    static let primary = Color("AccentColor") // Fallback; override below
    static let amber = Color(light: .init(red: 0.76, green: 0.58, blue: 0.32),
                             dark: .init(red: 0.88, green: 0.72, blue: 0.45))
    static let sage = Color(light: .init(red: 0.52, green: 0.62, blue: 0.48),
                            dark: .init(red: 0.62, green: 0.74, blue: 0.56))
    static let warmIndigo = Color(light: .init(red: 0.42, green: 0.40, blue: 0.58),
                                  dark: .init(red: 0.58, green: 0.55, blue: 0.75))
    static let clay = Color(light: .init(red: 0.72, green: 0.52, blue: 0.44),
                            dark: .init(red: 0.82, green: 0.62, blue: 0.52))

    // Backgrounds — warm parchment tones
    static let background = Color(light: .init(red: 0.98, green: 0.96, blue: 0.92),
                                  dark: .init(red: 0.10, green: 0.09, blue: 0.08))
    static let secondaryBackground = Color(light: .init(red: 0.95, green: 0.92, blue: 0.87),
                                           dark: .init(red: 0.15, green: 0.13, blue: 0.12))
    static let tertiaryBackground = Color(light: .init(red: 0.92, green: 0.89, blue: 0.83),
                                          dark: .init(red: 0.19, green: 0.17, blue: 0.15))
    static let cardBackground = Color(light: .init(red: 1.0, green: 0.98, blue: 0.95),
                                      dark: .init(red: 0.14, green: 0.12, blue: 0.11))

    // Text
    static let label = Color(light: .init(red: 0.20, green: 0.16, blue: 0.12),
                             dark: .init(red: 0.92, green: 0.88, blue: 0.82))
    static let secondaryLabel = Color(light: .init(red: 0.46, green: 0.42, blue: 0.36),
                                      dark: .init(red: 0.64, green: 0.60, blue: 0.54))
    static let separator = Color(light: .init(red: 0.85, green: 0.81, blue: 0.75),
                                 dark: .init(red: 0.24, green: 0.22, blue: 0.19))

    // Metric colors — warm-shifted
    static let mood = Color(light: .init(red: 0.55, green: 0.62, blue: 0.78),
                            dark: .init(red: 0.65, green: 0.72, blue: 0.88))
    static let energy = Color(light: .init(red: 0.82, green: 0.65, blue: 0.38),
                              dark: .init(red: 0.90, green: 0.75, blue: 0.48))
    static let stress = Color(light: .init(red: 0.78, green: 0.45, blue: 0.42),
                              dark: .init(red: 0.88, green: 0.55, blue: 0.50))
    static let sleep = Color(light: .init(red: 0.55, green: 0.50, blue: 0.70),
                             dark: .init(red: 0.68, green: 0.62, blue: 0.82))

    // Semantic
    static let safe = sage
    static let warning = Color(light: .init(red: 0.85, green: 0.72, blue: 0.35),
                               dark: .init(red: 0.92, green: 0.80, blue: 0.45))
    static let danger = Color(light: .init(red: 0.75, green: 0.32, blue: 0.30),
                              dark: .init(red: 0.88, green: 0.42, blue: 0.38))
    static let crisisBackground = Color(light: .init(red: 0.75, green: 0.32, blue: 0.30).opacity(0.08),
                                        dark: .init(red: 0.88, green: 0.42, blue: 0.38).opacity(0.12))

    // Lens colors — warm-shifted
    static let groundingLens = Color(light: .init(red: 0.45, green: 0.62, blue: 0.58),
                                     dark: .init(red: 0.55, green: 0.74, blue: 0.68))
    static let meaningLens = warmIndigo
    static let integrationLens = sage

    // Tab bar
    static let tabBarBackground = Color(light: .init(red: 0.97, green: 0.94, blue: 0.90),
                                        dark: .init(red: 0.12, green: 0.10, blue: 0.09))
    static let tabInactive = Color(light: .init(red: 0.62, green: 0.58, blue: 0.52),
                                   dark: .init(red: 0.48, green: 0.44, blue: 0.40))
}

// MARK: - Adaptive Color Helper

extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(dark)
                : NSColor(light)
        })
        #endif
    }
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Shadow

enum AppShadow {
    static func soft(color: Color = .black.opacity(0.06), radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        Color.clear.shadow(color: color, radius: radius, x: 0, y: y)
    }
}

// MARK: - Card Style Modifier (Quiet Depth)

struct CardStyle: ViewModifier {
    var padded: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padded ? Spacing.lg : 0)
            .background(AppColor.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(AppColor.separator.opacity(0.3), lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func cardStyle(padded: Bool) -> some View {
        modifier(CardStyle(padded: padded))
    }
}

// MARK: - Warm Gradient Backgrounds

enum AppGradient {
    static let warmCTA = LinearGradient(
        colors: [AppColor.amber, AppColor.clay],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pageBackground = LinearGradient(
        colors: [AppColor.background, AppColor.secondaryBackground.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardWarmth = LinearGradient(
        colors: [AppColor.amber.opacity(0.06), AppColor.amber.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Entrance Animation Modifier

struct FadeRise: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func fadeRise(delay: Double = 0) -> some View {
        modifier(FadeRise(delay: delay))
    }
}

// MARK: - Breathing Pulse Modifier

struct BreathingPulse: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.015 : 1.0)
            .shadow(color: AppColor.amber.opacity(isPulsing ? 0.15 : 0.05),
                    radius: isPulsing ? 12 : 6, x: 0, y: 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func breathingPulse() -> some View {
        modifier(BreathingPulse())
    }
}

// MARK: - Warm Page Background

struct WarmBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColor.background.ignoresSafeArea())
    }
}

extension View {
    func warmBackground() -> some View {
        modifier(WarmBackground())
    }
}

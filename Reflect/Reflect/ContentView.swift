import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    enum AppTab: Int, CaseIterable {
        case today, reflect, moments, insights, settings

        var label: String {
            switch self {
            case .today: return Strings.tabToday
            case .reflect: return Strings.tabReflect
            case .moments: return Strings.tabMoments
            case .insights: return Strings.tabInsights
            case .settings: return Strings.tabSettings
            }
        }

        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .reflect: return "brain.head.profile"
            case .moments: return "sparkles.rectangle.stack"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }

        var iconFilled: String {
            switch self {
            case .today: return "sun.max.fill"
            case .reflect: return "brain.head.profile.fill"
            case .moments: return "sparkles.rectangle.stack.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .today: TodayView()
                case .reflect: ReflectTabView()
                case .moments: MomentsGalleryView()
                case .insights: InsightsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .warmBackground()
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .background(
            AppColor.tabBarBackground
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    // Glow behind selected icon
                    if selectedTab == tab {
                        Circle()
                            .fill(AppColor.amber.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)
                    }

                    Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                        .font(.system(size: 20))
                        .foregroundColor(selectedTab == tab ? AppColor.amber : AppColor.tabInactive)
                        .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                }
                .frame(height: 28)

                Text(tab.label)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(selectedTab == tab ? AppColor.amber : AppColor.tabInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}

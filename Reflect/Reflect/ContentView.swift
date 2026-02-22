import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(Strings.tabToday, systemImage: "sun.max.fill")
                }

            ReflectTabView()
                .tabItem {
                    Label(Strings.tabReflect, systemImage: "brain.head.profile")
                }

            MomentsGalleryView()
                .tabItem {
                    Label(Strings.tabMoments, systemImage: "sparkles.rectangle.stack.fill")
                }

            InsightsView()
                .tabItem {
                    Label(Strings.tabInsights, systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label(Strings.tabSettings, systemImage: "gearshape.fill")
                }
        }
    }
}

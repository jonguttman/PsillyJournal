import SwiftUI

/// Simple bar chart showing daily metrics for the past 7 days.
/// Uses native SwiftUI shapes (no Charts framework dependency for maximum compatibility).
struct TrendsView: View {
    let metrics: [InsightsViewModel.DailyMetric]

    @State private var selectedMetric: MetricType = .mood

    enum MetricType: String, CaseIterable, Identifiable {
        case mood = "Mood"
        case energy = "Energy"
        case stress = "Stress"
        case sleepQuality = "Sleep"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .mood: return AppColor.mood
            case .energy: return AppColor.energy
            case .stress: return AppColor.stress
            case .sleepQuality: return AppColor.sleep
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Metric selector
            Picker("Metric", selection: $selectedMetric) {
                ForEach(MetricType.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            // Chart
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(metrics) { metric in
                    VStack(spacing: Spacing.xs) {
                        // Value label
                        let value = valueForMetric(metric)
                        if value > 0 {
                            Text(String(format: "%.0f", value))
                                .font(AppFont.captionSecondary)
                                .foregroundColor(selectedMetric.color)
                                .monospacedDigit()
                        }

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(value > 0 ? selectedMetric.color : AppColor.secondaryLabel.opacity(0.2))
                            .frame(height: barHeight(for: value))

                        // Day label
                        Text(metric.dayLabel)
                            .font(AppFont.captionSecondary)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
            .padding(.vertical, Spacing.sm)
        }
        .cardStyle()
    }

    private func valueForMetric(_ metric: InsightsViewModel.DailyMetric) -> Double {
        switch selectedMetric {
        case .mood: return metric.mood
        case .energy: return metric.energy
        case .stress: return metric.stress
        case .sleepQuality: return metric.sleepQuality
        }
    }

    private func barHeight(for value: Double) -> CGFloat {
        let maxHeight: CGFloat = 120
        guard value > 0 else { return 8 } // minimum bar for "no data" days
        return max(8, (value / 10.0) * maxHeight)
    }
}

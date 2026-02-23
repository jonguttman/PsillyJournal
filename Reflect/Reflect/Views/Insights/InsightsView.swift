import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InsightsViewModel()
    @State private var showWeeklyLetter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if !viewModel.hasEnoughData {
                        emptyState
                    } else {
                        trendsSection
                            .fadeRise(delay: 0)
                        averagesSection
                            .fadeRise(delay: 0.1)
                        weeklyLetterSection
                            .fadeRise(delay: 0.2)
                    }

                    Spacer().frame(height: 80)
                }
                .padding(Spacing.lg)
            }
            .warmBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle(Strings.insightsTitle)
            .onAppear { viewModel.setup(context: modelContext) }
            .sheet(isPresented: $showWeeklyLetter) {
                if let letter = viewModel.currentLetter {
                    WeeklyLetterView(letter: letter, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: Strings.insightsNoData,
            message: Strings.insightsNoDataBody
        )
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Strings.insightsTrends)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)

            TrendsView(metrics: viewModel.dailyMetrics)
        }
    }

    // MARK: - Averages

    private var averagesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("7-Day Averages")
                .font(AppFont.headline)
                .foregroundColor(AppColor.label)

            HStack(spacing: Spacing.md) {
                averageCard(
                    label: Strings.checkInMood,
                    value: viewModel.averageMood,
                    color: AppColor.mood
                )
                averageCard(
                    label: Strings.checkInEnergy,
                    value: viewModel.averageEnergy,
                    color: AppColor.energy
                )
                averageCard(
                    label: Strings.checkInStress,
                    value: viewModel.averageStress,
                    color: AppColor.stress
                )
                averageCard(
                    label: "Sleep",
                    value: viewModel.averageSleepQuality,
                    color: AppColor.sleep
                )
            }
        }
        .cardStyle()
    }

    private func averageCard(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(String(format: "%.1f", value))
                .font(AppFont.metricLarge)
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(AppFont.captionSecondary)
                .foregroundColor(AppColor.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Letter

    private var weeklyLetterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Strings.insightsWeeklyLetter)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)

            if let letter = viewModel.currentLetter {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(letter.dateRangeFormatted)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)

                    Text(letter.fullText)
                        .font(.system(.body, design: .serif))
                        .foregroundColor(AppColor.secondaryLabel)
                        .lineLimit(6)

                    // Warm separator
                    Rectangle()
                        .fill(AppColor.separator.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.vertical, Spacing.xs)

                    HStack {
                        Button(action: { showWeeklyLetter = true }) {
                            Text("Read Full Letter")
                                .font(AppFont.callout)
                                .foregroundColor(AppColor.amber)
                        }
                        Spacer()
                        Button(action: { viewModel.regenerateWeeklyLetter() }) {
                            Label(Strings.insightsRegenerateLetter, systemImage: "arrow.clockwise")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColor.secondaryLabel)
                    }
                }
                .cardStyle()
            } else {
                Button(action: {
                    viewModel.generateWeeklyLetter()
                    showWeeklyLetter = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(Strings.insightsGenerateLetter)
                                .font(AppFont.headline)
                                .foregroundColor(.white)
                            Text("Reflect on the past 7 days")
                                .font(AppFont.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "envelope.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(Spacing.xl)
                    .background(AppGradient.warmCTA)
                    .cornerRadius(CornerRadius.lg)
                    .shadow(color: AppColor.amber.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isGeneratingLetter)
            }
        }
    }
}

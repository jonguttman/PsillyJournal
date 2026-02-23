import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var showCheckInForm = false
    @State private var editingCheckIn: CheckIn?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Greeting
                greetingSection
                    .fadeRise(delay: 0)

                // Check-in CTA or today's summary
                Group {
                    if viewModel.hasCheckedInToday, let checkIn = viewModel.todayCheckIn {
                        todayCheckInCard(checkIn)
                    } else {
                        checkInCTA
                    }
                }
                .fadeRise(delay: 0.1)

                // Recent moment
                if let moment = viewModel.recentMoment {
                    recentMomentCard(moment)
                        .fadeRise(delay: 0.2)
                }

                // Inspirational prompt when no content yet
                if !viewModel.hasCheckedInToday && viewModel.recentCheckIns.isEmpty {
                    dailyPrompt
                        .fadeRise(delay: 0.25)
                }

                // Recent check-ins
                if !viewModel.recentCheckIns.isEmpty {
                    recentCheckInsSection
                        .fadeRise(delay: 0.3)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.sm)
        }
        .onAppear { viewModel.setup(context: modelContext) }
        .sheet(isPresented: $showCheckInForm) {
            CheckInFormView(editingCheckIn: editingCheckIn) {
                viewModel.refresh()
                showCheckInForm = false
                editingCheckIn = nil
            }
        }
        .onChange(of: showCheckInForm) { _, newValue in
            if !newValue { editingCheckIn = nil }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.greeting)
                .font(AppFont.largeTitle)
                .foregroundColor(AppColor.label)
            Text(Strings.todayGreeting)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)

            // Subtle warm divider
            Rectangle()
                .fill(AppGradient.warmCTA)
                .frame(width: 40, height: 2)
                .cornerRadius(1)
                .padding(.top, Spacing.xs)
        }
    }

    // MARK: - Check-in CTA

    private var checkInCTA: some View {
        Button(action: { showCheckInForm = true }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.todayCheckInCTA)
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                    Text("Track your mood, energy, and sleep")
                        .font(AppFont.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(Spacing.xl)
            .background(AppGradient.warmCTA)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: AppColor.amber.opacity(0.25), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .breathingPulse()
    }

    // MARK: - Daily Inspirational Prompt

    private var dailyPrompt: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundColor(AppColor.sage)
                Text("Thought for today")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.sage)
            }

            Text("\u{201C}The real voyage of discovery consists not in seeking new landscapes, but in having new eyes.\u{201D}")
                .font(.system(.callout, design: .serif))
                .italic()
                .foregroundColor(AppColor.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            Text("— Marcel Proust")
                .font(AppFont.captionSecondary)
                .foregroundColor(AppColor.secondaryLabel.opacity(0.6))
        }
        .cardStyle()
    }

    // MARK: - Today's Check-in Card

    private func todayCheckInCard(_ checkIn: CheckIn) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(Strings.todayLastCheckIn)
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)
                Spacer()
                Button(action: {
                    editingCheckIn = checkIn
                    showCheckInForm = true
                }) {
                    Text(Strings.edit)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.amber)
                }
            }

            HStack(spacing: Spacing.md) {
                MetricBadge(label: Strings.checkInMood, value: checkIn.mood, color: AppColor.mood)
                MetricBadge(label: Strings.checkInEnergy, value: checkIn.energy, color: AppColor.energy)
                MetricBadge(label: Strings.checkInStress, value: checkIn.stress, color: AppColor.stress)
                MetricBadge(label: "Sleep", value: checkIn.sleepQuality, color: AppColor.sleep)
            }

            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)
                    .lineLimit(3)
            }
        }
        .cardStyle()
    }

    // MARK: - Recent Moment

    private func recentMomentCard(_ moment: Moment) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(Strings.todayRecentMoment)
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)
                Spacer()
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundColor(AppColor.amber.opacity(0.6))
            }

            Text("\"\(moment.quote)\"")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(AppColor.secondaryLabel)
                .lineLimit(3)

            if !moment.themes.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(moment.themes.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(AppFont.captionSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColor.sage.opacity(0.12))
                            .foregroundColor(AppColor.sage)
                            .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Recent Check-ins

    private var recentCheckInsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Check-ins")
                .font(AppFont.headline)
                .foregroundColor(AppColor.label)

            ForEach(viewModel.recentCheckIns.prefix(5), id: \.id) { checkIn in
                HStack {
                    Text(checkIn.formattedDate)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                    Spacer()
                    HStack(spacing: Spacing.md) {
                        miniMetric(value: checkIn.mood, color: AppColor.mood)
                        miniMetric(value: checkIn.energy, color: AppColor.energy)
                        miniMetric(value: checkIn.stress, color: AppColor.stress)
                    }
                }
                .padding(.vertical, Spacing.xs)
                if checkIn.id != viewModel.recentCheckIns.prefix(5).last?.id {
                    Rectangle()
                        .fill(AppColor.separator.opacity(0.3))
                        .frame(height: 0.5)
                }
            }
        }
        .cardStyle()
    }

    private func miniMetric(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(AppFont.metricSmall)
            .monospacedDigit()
            .foregroundColor(color)
            .frame(width: 24)
    }
}

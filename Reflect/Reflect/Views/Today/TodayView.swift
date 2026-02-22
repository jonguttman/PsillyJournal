import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var showCheckInForm = false
    @State private var editingCheckIn: CheckIn?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Greeting
                    greetingSection

                    // Check-in CTA or today's summary
                    if viewModel.hasCheckedInToday, let checkIn = viewModel.todayCheckIn {
                        todayCheckInCard(checkIn)
                    } else {
                        checkInCTA
                    }

                    // Recent moment
                    if let moment = viewModel.recentMoment {
                        recentMomentCard(moment)
                    }

                    // Recent check-ins
                    if !viewModel.recentCheckIns.isEmpty {
                        recentCheckInsSection
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle(Strings.tabToday)
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
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.greeting)
                .font(AppFont.largeTitle)
                .foregroundColor(AppColor.label)
            Text(Strings.todayGreeting)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
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
            .padding(Spacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColor.primary, AppColor.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
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
                        .foregroundColor(AppColor.primary)
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
            Text(Strings.todayRecentMoment)
                .font(AppFont.headline)
                .foregroundColor(AppColor.label)

            Text("\"\(moment.quote)\"")
                .font(AppFont.body)
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
                            .background(AppColor.primary.opacity(0.1))
                            .cornerRadius(CornerRadius.xl)
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
                    HStack(spacing: Spacing.sm) {
                        miniMetric("😊", value: checkIn.mood)
                        miniMetric("⚡", value: checkIn.energy)
                        miniMetric("😰", value: checkIn.stress)
                    }
                }
                .padding(.vertical, Spacing.xs)
                if checkIn.id != viewModel.recentCheckIns.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private func miniMetric(_ emoji: String, value: Int) -> some View {
        Text("\(emoji) \(value)")
            .font(AppFont.captionSecondary)
            .monospacedDigit()
    }
}

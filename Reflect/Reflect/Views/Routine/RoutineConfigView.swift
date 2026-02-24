// Reflect/Views/Routine/RoutineConfigView.swift
import SwiftUI

struct RoutineConfigView: View {
    let product: VerifiedProduct
    let onSave: (RoutineSchedule, [Int]?, Bool, Date?, String?) -> Void

    @State private var schedule: RoutineSchedule = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    )!
    @State private var notes = ""

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Product header
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppColor.sage)
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(AppFont.headline)
                                .foregroundColor(AppColor.label)
                            Text(product.category)
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }
                    .padding(Spacing.lg)
                    .cardStyle()

                    // Schedule
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(Strings.routineSchedule)
                            .font(AppFont.headline)
                            .foregroundColor(AppColor.label)

                        HStack(spacing: Spacing.sm) {
                            ForEach(RoutineSchedule.allCases, id: \.rawValue) { option in
                                Button(action: { schedule = option }) {
                                    Text(option.displayName)
                                        .font(AppFont.caption)
                                        .foregroundColor(schedule == option ? .white : AppColor.label)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(schedule == option ? AppColor.amber : AppColor.cardBackground)
                                        .cornerRadius(CornerRadius.pill)
                                }
                            }
                        }
                    }

                    // Day picker (for weekly/custom)
                    if schedule == .weekly || schedule == .custom {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Days")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)

                            HStack(spacing: Spacing.sm) {
                                ForEach(1...7, id: \.self) { day in
                                    Button(action: { toggleDay(day) }) {
                                        Text(dayNames[day - 1])
                                            .font(AppFont.caption)
                                            .foregroundColor(selectedDays.contains(day) ? .white : AppColor.label)
                                            .frame(width: 40, height: 40)
                                            .background(selectedDays.contains(day) ? AppColor.amber : AppColor.cardBackground)
                                            .cornerRadius(CornerRadius.sm)
                                    }
                                }
                            }
                        }
                    }

                    // Reminder
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Toggle(isOn: $reminderEnabled) {
                            Text(Strings.routineReminder)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.label)
                        }
                        .tint(AppColor.amber)

                        if reminderEnabled {
                            DatePicker(
                                Strings.routineReminderTime,
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(AppFont.body)
                            .foregroundColor(AppColor.label)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(Strings.routineNotes)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(AppFont.body)
                            .lineLimit(3)
                            .padding(Spacing.md)
                            .background(AppColor.cardBackground)
                            .cornerRadius(CornerRadius.md)
                    }

                    // Save button
                    Button(action: save) {
                        Text(Strings.routineStartCTA)
                            .font(AppFont.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(AppGradient.warmCTA)
                            .cornerRadius(CornerRadius.lg)
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(Spacing.xl)
            }
            .warmBackground()
            .navigationTitle(Strings.routineConfigureTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    private func save() {
        let days = selectedDays.isEmpty ? nil : Array(selectedDays).sorted()
        onSave(
            schedule,
            days,
            reminderEnabled,
            reminderEnabled ? reminderTime : nil,
            notes.isEmpty ? nil : notes
        )
    }
}

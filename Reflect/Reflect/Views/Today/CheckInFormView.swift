import SwiftUI
import SwiftData

struct CheckInFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CheckInViewModel()

    var editingCheckIn: CheckIn?
    var onSave: () -> Void

    // Local bindings for voice note path
    @State private var voiceNotePath: String?

    var body: some View {
        NavigationStack {
            Form {
                // Mood
                Section {
                    MetricSliderView(
                        label: Strings.checkInMood,
                        value: $viewModel.mood,
                        color: AppColor.mood
                    )
                }
                .listRowBackground(AppColor.cardBackground)

                // Energy
                Section {
                    MetricSliderView(
                        label: Strings.checkInEnergy,
                        value: $viewModel.energy,
                        color: AppColor.energy
                    )
                }
                .listRowBackground(AppColor.cardBackground)

                // Stress
                Section {
                    MetricSliderView(
                        label: Strings.checkInStress,
                        value: $viewModel.stress,
                        color: AppColor.stress
                    )
                }
                .listRowBackground(AppColor.cardBackground)

                // Sleep
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text(Strings.checkInSleepHours)
                                .font(AppFont.callout)
                                .foregroundColor(AppColor.label)
                            Spacer()
                            Text(String(format: "%.1f h", viewModel.sleepHours))
                                .font(AppFont.metricLarge)
                                .foregroundColor(AppColor.sleep)
                                .monospacedDigit()
                        }
                        Slider(value: $viewModel.sleepHours, in: 0...14, step: 0.5)
                            .tint(AppColor.sleep)
                    }
                    MetricSliderView(
                        label: Strings.checkInSleepQuality,
                        value: $viewModel.sleepQuality,
                        color: AppColor.sleep
                    )
                }
                .listRowBackground(AppColor.cardBackground)

                // Note
                Section(header: Text("Notes")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.amber.opacity(0.8))
                    .textCase(nil)
                ) {
                    TextEditor(text: $viewModel.note)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.label)
                        .frame(minHeight: 80)
                        .overlay(
                            Group {
                                if viewModel.note.isEmpty {
                                    Text(Strings.checkInNote)
                                        .font(AppFont.body)
                                        .foregroundColor(AppColor.secondaryLabel.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                .listRowBackground(AppColor.cardBackground)

                // Voice Note
                Section {
                    VoiceNoteButton(voiceNotePath: $voiceNotePath)
                }
                .listRowBackground(AppColor.cardBackground)

                // Delete (if editing)
                if viewModel.isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let checkIn = editingCheckIn {
                                _ = viewModel.delete(checkIn)
                                onSave()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(Strings.checkInDelete)
                            }
                            .foregroundColor(AppColor.danger)
                        }
                    }
                    .listRowBackground(AppColor.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .warmBackground()
            .navigationTitle(viewModel.isEditing ? Strings.checkInEdit : Strings.checkInTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.cancel) { dismiss() }
                        .foregroundColor(AppColor.secondaryLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.save) {
                        viewModel.voiceNotePath = voiceNotePath
                        if viewModel.save() {
                            onSave()
                        }
                    }
                    .foregroundColor(AppColor.amber)
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                viewModel.setup(context: modelContext)
                if let checkIn = editingCheckIn {
                    viewModel.loadForEditing(checkIn)
                    voiceNotePath = checkIn.voiceNotePath
                }
            }
            .alert(Strings.safetyBlockedTitle, isPresented: $viewModel.showSafetyAlert) {
                Button(Strings.done, role: .cancel) {}
            } message: {
                Text(viewModel.safetyAlertMessage)
            }
            .sheet(isPresented: $viewModel.showCrisisSheet) {
                CrisisResourcesView()
            }
        }
    }
}

import SwiftUI

struct WeeklyLetterView: View {
    let letter: WeeklyLetter
    @Bindable var viewModel: InsightsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(Strings.weeklyLetterTitle)
                            .font(AppFont.largeTitle)
                            .foregroundColor(AppColor.label)

                        Text(letter.dateRangeFormatted)
                            .font(AppFont.callout)
                            .foregroundColor(AppColor.secondaryLabel)
                    }

                    Divider()

                    // Full letter text
                    Text(letter.fullText)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.label)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)

                    Divider()

                    // Actions
                    HStack(spacing: Spacing.md) {
                        // Export
                        Button(action: exportLetter) {
                            Label(Strings.weeklyLetterExport, systemImage: "square.and.arrow.up")
                                .font(AppFont.callout)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        // Regenerate
                        Button(action: {
                            viewModel.regenerateWeeklyLetter()
                            dismiss()
                        }) {
                            Label(Strings.insightsRegenerateLetter, systemImage: "arrow.clockwise")
                                .font(AppFont.callout)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.done) { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func exportLetter() {
        do {
            exportURL = try ExportService.writeToTempFile(
                text: letter.fullText,
                filename: "weekly_reflection_letter.txt"
            )
            showShareSheet = true
        } catch {
            // Export failed silently
        }
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

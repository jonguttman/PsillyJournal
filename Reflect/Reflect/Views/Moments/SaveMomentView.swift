import SwiftUI
import SwiftData

struct SaveMomentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let sourceType: MomentSourceType
    let sourceId: UUID
    var prefilledQuote: String = ""

    @State private var quote: String = ""
    @State private var themes: [String] = []
    @State private var emotions: [String] = []
    @State private var intensity: Int = 5
    @State private var askOfMe: String = ""

    private let maxQuoteLength = 240

    var body: some View {
        NavigationStack {
            Form {
                // Quote
                Section(header: Text(Strings.momentsQuote)) {
                    TextEditor(text: $quote)
                        .frame(minHeight: 80)
                        .onChange(of: quote) { _, newValue in
                            if newValue.count > maxQuoteLength {
                                quote = String(newValue.prefix(maxQuoteLength))
                            }
                        }

                    HStack {
                        Spacer()
                        Text("\(quote.count)/\(maxQuoteLength)")
                            .font(AppFont.captionSecondary)
                            .foregroundColor(
                                quote.count >= maxQuoteLength ? AppColor.danger : AppColor.secondaryLabel
                            )
                    }
                }

                // Themes
                Section {
                    TagPickerView(
                        title: Strings.momentsThemes,
                        allTags: ReflectionTheme.allCases,
                        selectedTags: $themes
                    )
                }

                // Emotions
                Section {
                    TagPickerView(
                        title: Strings.momentsEmotions,
                        allTags: EmotionTag.allCases,
                        selectedTags: $emotions
                    )
                }

                // Intensity
                Section {
                    MetricSliderView(
                        label: Strings.reflectIntensity,
                        value: $intensity,
                        range: 0...10,
                        color: AppColor.energy
                    )
                }

                // What this asks of me
                Section(header: Text(Strings.momentsAskOfMe)) {
                    TextField("One line...", text: $askOfMe)
                }
            }
            .navigationTitle(Strings.momentsSaveCTA)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.save) {
                        saveMoment()
                    }
                    .disabled(quote.isEmpty)
                }
            }
            .onAppear {
                if quote.isEmpty && !prefilledQuote.isEmpty {
                    quote = String(prefilledQuote.prefix(maxQuoteLength))
                }
            }
        }
    }

    private func saveMoment() {
        let moment = Moment(
            quote: String(quote.prefix(maxQuoteLength)),
            themes: themes,
            emotions: emotions,
            intensity: intensity,
            askOfMe: askOfMe,
            sourceType: sourceType,
            sourceId: sourceId
        )
        modelContext.insert(moment)
        try? modelContext.save()
        dismiss()
    }
}

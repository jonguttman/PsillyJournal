import SwiftUI

/// A labeled slider for rating metrics on a 1–10 (or 0–10) scale.
/// Quiet Depth: warm tint, serif value display, subtle track styling.
struct MetricSliderView: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10
    var color: Color = AppColor.amber
    var showValue: Bool = true

    private var doubleValue: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { value = Int($0.rounded()) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .lastTextBaseline) {
                Text(label)
                    .font(AppFont.callout)
                    .foregroundColor(AppColor.label)
                Spacer()
                if showValue {
                    Text("\(value)")
                        .font(AppFont.metricLarge)
                        .foregroundColor(color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: value)
                }
            }
            Slider(
                value: doubleValue,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(color)

            HStack {
                Text("\(range.lowerBound)")
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
                Spacer()
                Text("\(range.upperBound)")
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

/// A warm metric display badge for read-only contexts.
/// Quiet Depth: soft warm glow, serif numerals, rounded pill shape.
struct MetricBadge: View {
    let label: String
    let value: Int
    var maxValue: Int = 10
    var color: Color = AppColor.amber

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .font(AppFont.metricLarge)
                .foregroundColor(color)
                .monospacedDigit()

            Text(label)
                .font(AppFont.captionSecondary)
                .foregroundColor(AppColor.secondaryLabel)
        }
        .frame(minWidth: 54)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

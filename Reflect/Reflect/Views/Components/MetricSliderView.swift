import SwiftUI

/// A labeled slider for rating metrics on a 1–10 (or 0–10) scale.
struct MetricSliderView: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10
    var color: Color = AppColor.primary
    var showValue: Bool = true

    private var doubleValue: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { value = Int($0.rounded()) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(AppFont.callout)
                    .foregroundColor(AppColor.label)
                Spacer()
                if showValue {
                    Text("\(value)")
                        .font(AppFont.headline)
                        .foregroundColor(color)
                        .monospacedDigit()
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

/// A smaller metric display for read-only contexts.
struct MetricBadge: View {
    let label: String
    let value: Int
    var maxValue: Int = 10
    var color: Color = AppColor.primary

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(value)")
                .font(AppFont.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFont.captionSecondary)
                .foregroundColor(AppColor.secondaryLabel)
        }
        .frame(minWidth: 50)
        .padding(Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

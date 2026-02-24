// Reflect/Views/Routine/ProductVerificationView.swift
import SwiftUI

struct ProductVerificationView: View {
    let product: VerifiedProduct
    let onAddToRoutine: () -> Void
    let onSaveForLater: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Verified badge
            ZStack {
                Circle()
                    .fill(AppColor.sage.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColor.sage)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            Text(Strings.routineVerified)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
                .opacity(appeared ? 1 : 0)

            // Product card
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(product.name)
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)

                HStack(spacing: Spacing.sm) {
                    Label(product.category, systemImage: "leaf.fill")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.sage)
                }

                if let batchId = product.batchId {
                    Text("Batch: \(batchId)")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)
                }

                Text("Verified on \(product.verifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
            }
            .padding(Spacing.xl)
            .cardStyle()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            // CTAs
            VStack(spacing: Spacing.md) {
                Button(action: onAddToRoutine) {
                    Text(Strings.routineAddToRoutine)
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradient.warmCTA)
                        .cornerRadius(CornerRadius.lg)
                }

                Button(action: onSaveForLater) {
                    Text(Strings.routineSaveForLater)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.secondaryLabel)
                }
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(Spacing.xxl)
        .warmBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

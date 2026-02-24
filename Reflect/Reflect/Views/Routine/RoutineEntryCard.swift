// Reflect/Views/Routine/RoutineEntryCard.swift
import SwiftUI

struct RoutineEntryCard: View {
    let entry: RoutineEntry
    let adherence: AdherenceResult
    let onLog: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Product info
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.sage)
                        Text(entry.product?.name ?? "Unknown")
                            .font(AppFont.headline)
                            .foregroundColor(AppColor.label)
                    }

                    Text(entry.product?.category ?? "")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)
                }
                Spacer()

                // Schedule badge
                Text(entry.schedule.displayName)
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.amber)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColor.amber.opacity(0.1))
                    .cornerRadius(CornerRadius.pill)
            }

            // Adherence bar
            if entry.schedule != .asNeeded {
                HStack(spacing: Spacing.sm) {
                    Text("\(Strings.routineAdherence): \(adherence.logged) of \(adherence.expected) days")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)

                    Spacer()

                    // Progress indicator
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColor.separator)
                                .frame(height: 4)
                            Capsule()
                                .fill(AppColor.sage)
                                .frame(
                                    width: geo.size.width * CGFloat(adherence.logged) / CGFloat(max(adherence.expected, 1)),
                                    height: 4
                                )
                        }
                    }
                    .frame(width: 60, height: 4)
                }
            }

            // Revoked banner
            if entry.product?.status == .revoked {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColor.danger)
                    Text(Strings.routineProductRevoked)
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.danger)
                }
                .padding(Spacing.sm)
                .background(AppColor.danger.opacity(0.08))
                .cornerRadius(CornerRadius.sm)
            }

            // Action buttons
            if entry.isActive && entry.product?.status != .revoked {
                HStack(spacing: Spacing.md) {
                    Button(action: onLog) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(Strings.routineLogToday)
                        }
                        .font(AppFont.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColor.sage)
                        .cornerRadius(CornerRadius.pill)
                    }

                    Button(action: onSkip) {
                        Text(Strings.routineSkip)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(AppColor.separator.opacity(0.3))
                            .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(padded: false)
    }
}

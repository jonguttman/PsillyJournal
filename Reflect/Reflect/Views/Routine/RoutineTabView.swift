// Reflect/Views/Routine/RoutineTabView.swift
import SwiftUI

struct RoutineTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RoutineViewModel()
    @State private var showScanner = false
    @State private var showVerification = false
    @State private var showConfig = false
    @State private var pendingProduct: VerifiedProduct?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Text(Strings.routineTitle)
                        .font(AppFont.largeTitle)
                        .foregroundColor(AppColor.label)
                    Spacer()
                    scanButton
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.sm)

                if viewModel.activeEntries.isEmpty && viewModel.pendingTokens.isEmpty {
                    emptyState
                } else {
                    // Pending tokens
                    if !viewModel.pendingTokens.isEmpty {
                        pendingSection
                    }

                    // Active routines
                    ForEach(viewModel.activeEntries, id: \.id) { entry in
                        RoutineEntryCard(
                            entry: entry,
                            adherence: viewModel.weeklyAdherence(for: entry),
                            onLog: {
                                viewModel.logEntry(entry)
                                try? modelContext.save()
                                viewModel.refresh()
                            },
                            onSkip: {
                                viewModel.logEntry(entry, skipped: true)
                                try? modelContext.save()
                                viewModel.refresh()
                            }
                        )
                        .padding(.horizontal, Spacing.xl)
                    }
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView(
                onScan: { urlString in
                    showScanner = false
                    if let token = viewModel.processScanResult(urlString) {
                        Task {
                            await viewModel.resolveToken(token)
                            if viewModel.resolvedProduct != nil {
                                showVerification = true
                            }
                        }
                    }
                },
                onCancel: { showScanner = false }
            )
        }
        .sheet(isPresented: $showVerification) {
            if let product = viewModel.resolvedProduct {
                ProductVerificationView(
                    product: product,
                    onAddToRoutine: {
                        pendingProduct = product
                        showVerification = false
                        showConfig = true
                    },
                    onSaveForLater: {
                        showVerification = false
                        viewModel.resolvedProduct = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showConfig) {
            if let product = pendingProduct {
                RoutineConfigView(product: product) { schedule, days, reminder, time, notes in
                    viewModel.addToRoutine(
                        product: product,
                        schedule: schedule,
                        scheduleDays: days,
                        reminderEnabled: reminder,
                        reminderTime: time,
                        notes: notes
                    )
                    try? modelContext.save()
                    pendingProduct = nil
                    showConfig = false
                    viewModel.refresh()
                }
            }
        }
        .alert(
            alertTitle,
            isPresented: .init(
                get: { viewModel.scanError != nil },
                set: { if !$0 { viewModel.scanError = nil } }
            )
        ) {
            Button(Strings.done) { viewModel.scanError = nil }
        } message: {
            Text(alertBody)
        }
    }

    private var scanButton: some View {
        Button(action: { showScanner = true }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "qrcode.viewfinder")
                Text(Strings.routineScanCTA)
            }
            .font(AppFont.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(AppGradient.warmCTA)
            .cornerRadius(CornerRadius.lg)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColor.sage.opacity(0.6))
            Text(Strings.routineEmpty)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
            Text(Strings.routineEmptyBody)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxxl)
        .fadeRise()
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.qrPendingBadge)
                .font(AppFont.caption)
                .foregroundColor(AppColor.warning)
                .padding(.horizontal, Spacing.xl)

            ForEach(viewModel.pendingTokens, id: \.id) { token in
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColor.warning)
                    Text(Strings.qrOfflineSavedBody)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                    Spacer()
                }
                .padding(Spacing.md)
                .cardStyle()
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private var alertTitle: String {
        switch viewModel.scanError {
        case .invalidQR: return Strings.qrInvalidTitle
        case .tokenNotFound: return Strings.qrNotFoundTitle
        case .tokenRevoked: return Strings.qrRevokedTitle
        case .rateLimited: return Strings.qrRateLimitedTitle
        case .serviceUnavailable: return Strings.qrUnavailableTitle
        case .cameraRequired: return Strings.qrCameraRequiredTitle
        case .pendingQueueFull: return Strings.qrQueueFailedTitle
        case nil: return ""
        }
    }

    private var alertBody: String {
        switch viewModel.scanError {
        case .invalidQR: return Strings.qrInvalidBody
        case .tokenNotFound: return Strings.qrNotFoundBody
        case .tokenRevoked: return Strings.qrRevokedBody
        case .rateLimited: return Strings.qrRateLimitedBody
        case .serviceUnavailable: return Strings.qrUnavailableBody
        case .cameraRequired: return Strings.qrCameraRequiredBody
        case .pendingQueueFull: return Strings.qrQueueFailedBody
        case nil: return ""
        }
    }
}

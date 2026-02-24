import SwiftUI
import SwiftData

@main
struct ReflectApp: App {
    @StateObject private var lockService = LockService()
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var connectivity = ConnectivityService()
    @State private var routineViewModel = RoutineViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appLockEnabled && !lockService.isUnlocked {
                    LockGateView()
                        .environmentObject(lockService)
                } else {
                    ContentView()
                        .environmentObject(lockService)
                }
            }
            .background(
                ZStack {
                    AppColor.background
                    FractalTexture()
                }
                .ignoresSafeArea()
            )
            .tint(AppColor.amber)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && appLockEnabled {
                    lockService.lock()
                }
                if newPhase == .active {
                    Task {
                        await routineViewModel.resolvePendingTokens()
                    }
                }
            }
            #if DEBUG
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "seedDataLoaded") {
                    let context = PersistenceService.shared.container.mainContext
                    SeedDataService.populate(context: context)
                    UserDefaults.standard.set(true, forKey: "seedDataLoaded")
                }
            }
            #endif
            .onAppear {
                let context = PersistenceService.shared.container.mainContext
                routineViewModel.setup(context: context)

                // Wire connectivity → pending resolution
                connectivity.onReconnect = {
                    Task {
                        await routineViewModel.resolvePendingTokens()
                    }
                }
            }
        }
        .modelContainer(PersistenceService.shared.container)
    }
}

// MARK: - Lock Gate View

struct LockGateView: View {
    @EnvironmentObject var lockService: LockService
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Warm glow halo behind icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColor.amber.opacity(0.15), AppColor.amber.opacity(0.0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppColor.amber)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)

            VStack(spacing: Spacing.sm) {
                Text(Strings.appName)
                    .font(AppFont.largeTitle)
                    .foregroundColor(AppColor.label)

                Text(Strings.appTagline)
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundColor(AppColor.secondaryLabel)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Button(action: unlock) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: lockService.biometricType == .faceID ? "faceid" : "touchid")
                    Text("Unlock with \(lockService.authMethodName)")
                }
                .font(AppFont.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(AppGradient.warmCTA)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: AppColor.amber.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.top, Spacing.lg)
            .opacity(appeared ? 1 : 0)

            if let error = lockService.errorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.danger)
                    .padding(.top, Spacing.sm)
            }

            Spacer()
        }
        .padding(Spacing.xxl)
        .warmBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
        .task {
            unlock()
        }
    }

    private func unlock() {
        Task {
            _ = await lockService.authenticate()
        }
    }
}

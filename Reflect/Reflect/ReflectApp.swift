import SwiftUI
import SwiftData

@main
struct ReflectApp: App {
    @StateObject private var lockService = LockService()
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase

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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && appLockEnabled {
                    lockService.lock()
                }
            }
        }
        .modelContainer(PersistenceService.shared.container)
    }
}

// MARK: - Lock Gate View

struct LockGateView: View {
    @EnvironmentObject var lockService: LockService

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColor.primary)

            Text(Strings.appName)
                .font(AppFont.largeTitle)
                .foregroundColor(AppColor.label)

            Text(Strings.appTagline)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)

            Button(action: unlock) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: lockService.biometricType == .faceID ? "faceid" : "touchid")
                    Text("Unlock with \(lockService.authMethodName)")
                }
                .font(AppFont.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(AppColor.primary)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.top, Spacing.lg)

            if let error = lockService.errorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.danger)
                    .padding(.top, Spacing.sm)
            }

            Spacer()
        }
        .padding(Spacing.xxl)
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

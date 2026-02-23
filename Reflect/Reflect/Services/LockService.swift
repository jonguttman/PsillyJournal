import Foundation
import LocalAuthentication

/// Manages biometric and passcode authentication for app lock.
@MainActor
final class LockService: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var biometricType: LABiometryType = .none
    @Published var isAvailable: Bool = false
    @Published var errorMessage: String?

    init() {
        checkAvailability()
    }

    /// Checks whether biometric or passcode authentication is available.
    func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        )
        if isAvailable {
            biometricType = context.biometryType
        }
        if let error {
            errorMessage = error.localizedDescription
        }
    }

    /// Attempts to authenticate the user. Returns true on success.
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedReason = "Unlock Reflect to access your journal"
        context.localizedCancelTitle = "Cancel"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication, // Falls back to passcode
                localizedReason: "Unlock Reflect to access your journal"
            )
            await MainActor.run {
                isUnlocked = success
                errorMessage = nil
            }
            return success
        } catch {
            await MainActor.run {
                isUnlocked = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }

    /// Locks the app.
    func lock() {
        isUnlocked = false
    }

    /// A human-readable description of the available authentication method.
    var authMethodName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Passcode"
        @unknown default: return "Passcode"
        }
    }
}

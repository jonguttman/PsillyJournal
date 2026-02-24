// Reflect/Services/ConnectivityService.swift
import Foundation
import Network

@Observable
@MainActor
final class ConnectivityService {
    var isConnected: Bool = true

    /// Called when connectivity transitions from offline -> online.
    /// Wire this to RoutineViewModel.resolvePendingTokens().
    var onReconnect: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.psilly.reflect.connectivity")
    private var wasDisconnected = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let connected = path.status == .satisfied
                let wasOff = self?.wasDisconnected ?? false
                self?.isConnected = connected

                if connected && wasOff {
                    self?.onReconnect?()
                }
                self?.wasDisconnected = !connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

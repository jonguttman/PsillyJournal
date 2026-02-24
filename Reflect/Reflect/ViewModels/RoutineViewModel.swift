// Reflect/ViewModels/RoutineViewModel.swift
import Foundation
import SwiftData

enum ScanError: Equatable {
    case invalidQR
    case tokenNotFound
    case tokenRevoked
    case rateLimited
    case serviceUnavailable
    case cameraRequired
    case pendingQueueFull
}

struct AdherenceResult {
    let logged: Int
    let expected: Int
}

@Observable
@MainActor
final class RoutineViewModel {
    var activeEntries: [RoutineEntry] = []
    var savedProducts: [VerifiedProduct] = []
    var pendingTokens: [PendingToken] = []

    // Scan state
    var isScanning = false
    var isResolving = false
    var scanError: ScanError?
    var resolvedProduct: VerifiedProduct?

    // Routine config
    var showRoutineConfig = false
    var showScanSheet = false

    private var context: ModelContext?
    private var apiService: TokenAPIServiceProtocol = StubTokenAPIService()

    func setup(context: ModelContext, apiService: TokenAPIServiceProtocol? = nil) {
        self.context = context
        if let api = apiService { self.apiService = api }
        refresh()
    }

    // MARK: - Data Fetch

    func refresh() {
        guard let context else { return }

        let activeDescriptor = FetchDescriptor<RoutineEntry>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.linkedAt, order: .reverse)]
        )
        activeEntries = (try? context.fetch(activeDescriptor)) ?? []

        let productDescriptor = FetchDescriptor<VerifiedProduct>(
            sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
        )
        savedProducts = (try? context.fetch(productDescriptor)) ?? []

        pendingTokens = (try? TokenResolutionService.pendingTokens(context: context)) ?? []
    }

    // MARK: - Scan Processing

    func processScanResult(_ urlString: String) -> String? {
        scanError = nil
        switch TokenResolutionService.parseScanResult(urlString) {
        case .success(let token):
            return token
        case .failure:
            scanError = .invalidQR
            return nil
        }
    }

    func resolveToken(_ token: String) async {
        guard let context else { return }
        isResolving = true
        scanError = nil

        // Check cache first
        if let cached = try? TokenResolutionService.findCachedProduct(token: token, context: context),
           !cached.isCacheStale {
            resolvedProduct = cached
            isResolving = false
            return
        }

        do {
            let response = try await apiService.resolveToken(token)
            let product = TokenResolutionService.createOrUpdateProduct(
                token: token,
                response: response,
                context: context
            )
            try context.save()
            resolvedProduct = product
        } catch let error as TokenAPIError {
            switch error {
            case .tokenNotFound: scanError = .tokenNotFound
            case .tokenInactive: scanError = .tokenRevoked
            case .rateLimited: scanError = .rateLimited
            case .serviceUnavailable, .serverError: scanError = .serviceUnavailable
            case .networkError:
                // Offline — queue the token
                do {
                    try TokenResolutionService.addToPendingQueue(token: token, context: context)
                    try context.save()
                } catch {
                    scanError = .pendingQueueFull
                }
            case .decodingError: scanError = .serviceUnavailable
            }
        } catch {
            scanError = .serviceUnavailable
        }

        isResolving = false
        refresh()
    }

    // MARK: - Routine CRUD

    @discardableResult
    func addToRoutine(
        product: VerifiedProduct,
        schedule: RoutineSchedule,
        scheduleDays: [Int]? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        notes: String? = nil
    ) -> RoutineEntry {
        let entry = RoutineEntry(
            product: product,
            schedule: schedule,
            scheduleDays: scheduleDays,
            reminderTime: reminderTime,
            reminderEnabled: reminderEnabled,
            notes: notes
        )
        context?.insert(entry)
        refresh()
        return entry
    }

    func deactivateEntry(_ entry: RoutineEntry) {
        entry.isActive = false
        try? context?.save()
        refresh()
    }

    // MARK: - Logging

    @discardableResult
    func logEntry(_ entry: RoutineEntry, skipped: Bool = false, note: String? = nil) -> RoutineLog {
        let log = RoutineLog(routineEntry: entry, skipped: skipped, note: note)
        context?.insert(log)
        return log
    }

    // MARK: - Adherence

    func weeklyAdherence(for entry: RoutineEntry) -> AdherenceResult {
        guard let context else { return AdherenceResult(logged: 0, expected: 7) }

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let entryId = entry.id

        let descriptor = FetchDescriptor<RoutineLog>(
            predicate: #Predicate {
                $0.routineEntry?.id == entryId &&
                $0.loggedAt >= weekAgo &&
                $0.skipped == false
            }
        )

        let logged = (try? context.fetchCount(descriptor)) ?? 0

        let expected: Int
        switch entry.schedule {
        case .daily: expected = 7
        case .weekly: expected = entry.scheduleDays?.count ?? 1
        case .asNeeded: expected = logged  // no target
        case .custom: expected = entry.scheduleDays?.count ?? 7
        }

        return AdherenceResult(logged: logged, expected: max(expected, 1))
    }

    // MARK: - Pending Queue Resolution

    func resolvePendingTokens() async {
        guard let context else { return }
        let pending = (try? TokenResolutionService.pendingTokens(context: context)) ?? []

        for token in pending {
            token.status = .resolving
            token.retryCount += 1
            token.lastRetryAt = Date()

            do {
                let response = try await apiService.resolveToken(token.token)
                TokenResolutionService.createOrUpdateProduct(
                    token: token.token,
                    response: response,
                    context: context
                )
                TokenResolutionService.removePendingToken(token, context: context)
            } catch let error as TokenAPIError {
                switch error {
                case .tokenNotFound, .tokenInactive:
                    token.status = .failed
                case .networkError:
                    token.status = .pending  // will retry later
                default:
                    if token.retryCount >= 3 {
                        token.status = .failed
                    } else {
                        token.status = .pending
                    }
                }
            } catch {
                token.status = .pending
            }
        }

        try? context.save()
        refresh()
    }
}

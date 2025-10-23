//
//  PurchaseManager.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/23/25.
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case proMonthly = "bn.pro.monthly"
        case lifetime   = "bn.lifetime"
        // future: case guideFasting = "bn.guide.fasting"
    }

    // MARK: - Products
    @Published private(set) var proMonthly: Product?
    @Published private(set) var lifetime: Product?
    // future: @Published private(set) var guideFasting: Product?

    // MARK: - Entitlement flags (bind UI to these)
    @Published private(set) var isPro: Bool = false                 // lifetime OR active sub
    @Published private(set) var subscriptionActive: Bool = false    // monthly sub currently active
    @Published private(set) var hasLifetime: Bool = false           // lifetime owned
    @Published private(set) var ownedNonConsumables: Set<String> = [] // guides/lifetime/etc.

    // MARK: - UX helpers
    @Published var purchaseInFlight: Bool = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    // MARK: - Lifecycle
    /// Call once at app launch.
    func start() {
        guard updatesTask == nil else { return } // avoid duplicate listeners
        updatesTask = listenForTransactions()
        Task { await refreshProductsAndEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Public API
    func refreshProductsAndEntitlements() async {
        await fetchProducts()
        await updateEntitlementsSafely()
    }

    func buyProMonthly() async {
        guard let product = proMonthly else { return }
        await purchase(product)
    }

    func buyLifetime() async {
        guard let product = lifetime else { return }
        await purchase(product)
    }

    func restore() async {
        do {
            try await AppStore.sync() // triggers entitlement updates
        } catch {
            lastError = error.localizedDescription
        }
    }

    func hasGuide(_ productID: String) -> Bool {
        isPro || ownedNonConsumables.contains(productID)
    }

    // MARK: - StoreKit plumbing
    private func fetchProducts() async {
        do {
            let ids = Set(ProductID.allCases.map(\.rawValue))
            let fetched = try await Product.products(for: ids)
            for p in fetched {
                switch p.id {
                case ProductID.proMonthly.rawValue: proMonthly = p
                case ProductID.lifetime.rawValue:   lifetime   = p
                default: break
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if case .verified(let t) = update {
                    await t.finish()
                    await self.updateEntitlementsSafely()
                }
            }
        }
    }

    private func purchase(_ product: Product) async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await updateEntitlementsSafely()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Entitlements
    private func updateEntitlementsSafely() async {
        do { try await updateEntitlements() }
        catch { lastError = error.localizedDescription }
    }

    /// Computes entitlements with proper expiry/revocation checks.
    private func updateEntitlements() async throws {
        var owned: Set<String> = []
        var subActive = false
        var lifetimeOwned = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }

            switch t.productID {
            case ProductID.proMonthly.rawValue:
                // Active if not revoked and expiration is in the future (or nil in rare sandbox cases)
                let active = (t.revocationDate == nil) && ((t.expirationDate ?? .distantFuture) > Date())
                if active { subActive = true }

            case ProductID.lifetime.rawValue:
                lifetimeOwned = true
                owned.insert(t.productID)

            default:
                // Any additional non-consumables (e.g., guides) land here
                owned.insert(t.productID)
            }
        }

        self.subscriptionActive = subActive
        self.hasLifetime = lifetimeOwned
        self.isPro = lifetimeOwned || subActive
        self.ownedNonConsumables = owned
    }
}

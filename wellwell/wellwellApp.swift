//
//  wellwellApp.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//
import SwiftUI
import StoreKit

@main
struct wellwellApp: App {
    @StateObject private var vm = TimerViewModel()
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(vm)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.prepare()
                }
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(vm)
                .environmentObject(purchaseManager)
        } label: {
            Text(menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }


    private var menuBarTitle: String {
        switch vm.state {
        case .idle:
            return "wellwell"
        case .focusRunning:
            return "focus \(vm.formattedTime())"
        case .waitingForBreakConfirmation:
            return "break?"
        case .breakRunning:
            return "break \(vm.formattedTime())"
        case .waitingForWorkConfirmation:
            return "work?"
        case .overdueBreak:
            return "break!"
        case .overdueWork:
            return "work!"
        }
    }

    private var menuBarSymbolName: String {
        switch vm.state {
        case .idle:
            return "cloud.sun"
        case .focusRunning:
            return "timer"
        case .waitingForBreakConfirmation, .overdueBreak:
            return "figure.walk"
        case .breakRunning:
            return "cup.and.saucer"
        case .waitingForWorkConfirmation, .overdueWork:
            return "arrow.clockwise"
        }
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    @AppStorage("isPro") var isPro = false

    private let proProductID = "com.yourapp.cloudpro"
    @Published var proProduct: Product?
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    private var updatesTask: Task<Void, Never>?
    private var didPrepare = false

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        guard !didPrepare else { return }
        didPrepare = true
        await loadProducts()
        await refreshEntitlements()
        listenForTransactions()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [proProductID])
            proProduct = products.first
        } catch {
            purchaseError = "Couldn't load Wellwell Pro right now. Please try again in a bit."
        }
    }

    func purchasePro() async {
        guard let product = proProduct else {
            purchaseError = "Wellwell Pro isn't available just yet. Please try again soon."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "We couldn't verify your purchase. Please try again."
                    return
                }
                isPro = true
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed. Please check your connection and try again."
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = "We couldn't restore purchases right now. Please try again."
        }
    }

    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task {
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                if transaction.productID == proProductID {
                    isPro = true
                }
                await transaction.finish()
            }
        }
    }

    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == proProductID {
                isPro = true
                return
            }
        }
    }
}

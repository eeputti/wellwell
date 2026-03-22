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

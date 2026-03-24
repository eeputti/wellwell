//
//  wellwellApp.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//
import SwiftUI
import StoreKit
import AppKit

@main
struct wellwellApp: App {
    @StateObject private var vm = TimerViewModel()
    @StateObject private var purchaseManager = PurchaseManager()
    @State private var menuBarExtraVisible = true

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .background(WindowConstraintsView(minSize: NSSize(width: 900, height: 720)))
                .environmentObject(vm)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.prepare()
                }
        }
        .commands {
            CommandMenu("Focus") {
                Button("Start Focus Session") {
                    vm.startWork()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Reset Timer") {
                    vm.resetTimer()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        Window("settings", id: "settings") {
            TimerSettingsView()
                .environmentObject(vm)
                .environmentObject(purchaseManager)
        }

        Window("stats", id: "stats") {
            StatsView()
                .environmentObject(vm)
        }

        MenuBarExtra(isInserted: $menuBarExtraVisible) {
            MenuBarContentView()
                .environmentObject(vm)
        } label: {
            Label(menuBarTitle, systemImage: menuBarSymbolName)
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


private struct WindowConstraintsView: NSViewRepresentable {
    let minSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            view.window?.minSize = minSize
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.minSize = minSize
        }
    }
}

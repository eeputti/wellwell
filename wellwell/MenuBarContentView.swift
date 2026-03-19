//
//  MenuBarContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//



import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject var vm: TimerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.openWindow) private var openWindow
    @State private var showPaywall = false
    @State private var showProSettings = false

    var body: some View {
        VStack(spacing: 14) {
            Image(characterImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 90)

            Text(vm.formattedTime())
                .font(.system(size: 34, weight: .light, design: .rounded))
                .monospacedDigit()

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                Button {
                    if purchaseManager.isPro {
                        showProSettings = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack {
                        Text("custom session lengths")
                        Spacer()
                        if purchaseManager.isPro {
                            Text("Pro unlocked")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Pro", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            
            
            Text(bubbleText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)

            if vm.state == .idle {
                Button("start work") {
                    vm.startWork()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
                Button("start break") {
                    vm.startBreak()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
                Button("resume work") {
                    vm.resumeWork()
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            Button("open main window") {
                openWindow(id: "main")
            }

            Button("quit wellwell") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 280)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showProSettings) {
            ProSessionSettingsView()
                .environmentObject(vm)
        }
    }

    private var statusText: String {
        switch vm.state {
        case .idle:
            return "ready to start"
        case .focusRunning:
            return "focus session"
        case .waitingForBreakConfirmation:
            return "time for a break"
        case .breakRunning:
            return "break session"
        case .waitingForWorkConfirmation:
            return "ready to continue?"
        case .overdueBreak:
            return "break overdue"
        case .overdueWork:
            return "work overdue"
        }
    }

    private var bubbleText: String {
        switch vm.state {
        case .idle:
            return "i'm ready when you are"
        case .focusRunning:
            return "keep up the good work!"
        case .waitingForBreakConfirmation:
            return "time for a break"
        case .breakRunning:
            return "nice job. now, breathe a little"
        case .waitingForWorkConfirmation:
            return "ready to continue?"
        case .overdueBreak:
            return "why aren’t you on a break yet??"
        case .overdueWork:
            return "are you asleep? it’s been a long break"
        }
    }

    private var characterImageName: String {
        switch vm.state {
        case .idle:
            return "well_idle"
        case .focusRunning:
            return "well_focus"
        case .waitingForBreakConfirmation:
            return "well_break_alert"
        case .breakRunning:
            return "well_break"
        case .waitingForWorkConfirmation:
            return "well_focus"
        case .overdueBreak:
            return "well_angry"
        case .overdueWork:
            return "well_sleep"
        }
    }
}

struct ProSessionSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Wellwell Pro")
                .font(.title2.weight(.semibold))
            Text("Customize your session lengths to match your flow.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Text("focus")
                Spacer()
                TextField("25", value: $vm.focusMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text("min")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("break")
                Spacer()
                TextField("5", value: $vm.breakMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text("min")
                    .foregroundStyle(.secondary)
            }

            Button("done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 320)
    }
}

struct ProPaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Image("well_idle")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 80)

            Text("unlock wellwell pro ☁️")
                .font(.title2.weight(.semibold))

            Text("Your cloud buddy wants to help you focus your way. Unlock Pro for custom session lengths forever.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let product = purchaseManager.proProduct {
                Text(product.displayPrice)
                    .font(.title3.weight(.medium))
            }

            Button {
                Task {
                    await purchaseManager.purchasePro()
                    if purchaseManager.isPro {
                        dismiss()
                    }
                }
            } label: {
                if purchaseManager.isPurchasing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("adopt cloud pro")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchaseManager.isPurchasing)

            Button("restore purchase") {
                Task {
                    await purchaseManager.restorePurchases()
                    if purchaseManager.isPro {
                        dismiss()
                    }
                }
            }
            .buttonStyle(.bordered)

            if let error = purchaseManager.purchaseError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

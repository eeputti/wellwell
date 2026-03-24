//
//  MenuBarContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//



import SwiftUI
import AppKit
import StoreKit

struct MenuBarContentView: View {
    @EnvironmentObject var vm: TimerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.openWindow) private var openWindow
    @AppStorage("selectedCharacterFamily") private var selectedCharacterFamilyValue = CharacterType.cloud.storedValue
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @State private var showPaywall = false
    @State private var showProSettings = false
    @State private var showStats = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Menu {
                    Button("settings") {
                        showSettings = true
                    }
                    Button("stats") {
                        showStats = true
                    }
                    Divider()
                    Button("open main window") {
                        openWindow(id: "main")
                    }
                    if vm.state != .idle {
                        Button("reset timer") {
                            vm.resetTimer()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3.weight(.semibold))
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            CharacterView(
                character: selectedCharacterFamily,
                expression: currentExpression,
                cloudColor: selectedCloudColor,
                isLocked: false
            )
                .frame(width: 120, height: 90)

            Text(vm.formattedTime())
                .font(.system(size: 34, weight: .light, design: .rounded))
                .monospacedDigit()

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button(primaryActionTitle) {
                handlePrimaryAction()
            }
            .buttonStyle(.borderedProminent)
            
            if vm.state == .idle {
                VStack(alignment: .leading, spacing: 4) {
                    Text("cloud color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CharacterColorPickerView(
                        selectedCloudColorValue: $selectedCloudColorValue,
                        swatchSize: 14,
                        spacing: 8,
                        selectedBorderColor: .primary,
                        unselectedBorderColor: Color.secondary.opacity(0.35)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                settingsPanel
            }
            
            
            Text(bubbleText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)

            if vm.showPostSessionFlow && vm.state == .waitingForBreakConfirmation {
                VStack(spacing: 6) {
                    Text("nice work ✨")
                        .font(.subheadline.weight(.semibold))
                    Text("today: \(vm.todaySessionCount) sessions • \(vm.todayFocusMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("take an earned break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
            }

            if vm.state == .idle {
                Button("start focus") {
                    vm.startWork()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
                Button("take an earned break") {
                    vm.startBreak()
                }
                .buttonStyle(.borderedProminent)

                Button("continue session at your own risk") {
                    vm.startWork()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .focusRunning {
                Button("take an earned break") {
                    vm.startBreak()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .breakRunning {
                Button("skip break") {
                    vm.resumeWork()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
                Button("i'm back again!") {
                    vm.resumeWork()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state != .idle {
                Button("reset timer") {
                    vm.resetTimer()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Button("open main window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("1", modifiers: [.command])

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
        .sheet(isPresented: $showStats) {
            StatsView()
                .environmentObject(vm)
        }
        .sheet(isPresented: $showSettings) {
            TimerSettingsView()
                .environmentObject(vm)
        }
    }

    private var statusText: String {
        switch vm.state {
        case .idle:
            return vm.hasCompletedSessionToday ? "you showed up today" : "ready when you are"
        case .focusRunning:
            return "work in progress"
        case .waitingForBreakConfirmation:
            return "time for a \(vm.upcomingBreakLabel)"
        case .breakRunning:
            return "\(vm.upcomingBreakLabel) session"
        case .waitingForWorkConfirmation:
            return "good to go again?"
        case .overdueBreak:
            return "gentle break reminder"
        case .overdueWork:
            return "restart gently"
        }
    }

    private var bubbleText: String {
        switch vm.state {
        case .idle:
            return vm.todaySessionCount == 0 ? "i’m ready when you are" : "one focused block is enough for today."
        case .focusRunning:
            return "keep up! you're doing great!"
        case .waitingForBreakConfirmation:
            return "time for a \(vm.upcomingBreakLabel)"
        case .breakRunning:
            return "whoa! it's break-time!"
        case .waitingForWorkConfirmation:
            return "come back, i miss you already."
        case .overdueBreak:
            return "whoa! it's break-time!"
        case .overdueWork:
            return "come back, i miss you already."
        }
    }

    private var currentExpression: ExpressionType {
        switch vm.state {
        case .idle:
            return .idle
        case .focusRunning:
            return .focus
        case .waitingForBreakConfirmation:
            return .breakStarting
        case .breakRunning:
            return .shortBreak
        case .waitingForWorkConfirmation:
            return .focus
        case .overdueBreak:
            return .noBreakWarning
        case .overdueWork:
            return .longBreak
        }
    }

    private var selectedCharacterFamily: CharacterType {
        CharacterType(storedValue: selectedCharacterFamilyValue)
    }

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
    }

    private var settingsPanel: some View {
        VStack(spacing: 8) {
            sliderRow(title: "focus", suffix: "min", value: $vm.focusMinutes, range: 1...120)
            sliderRow(title: "break", suffix: "min", value: $vm.breakMinutes, range: 1...60)
            sliderRow(title: "sessions", suffix: "", value: $vm.sessionsUntilLongBreak, range: 1...12)
            sliderRow(title: "long break", suffix: "min", value: $vm.longBreakMinutes, range: 1...90)
            Text("progress: \(vm.completedSessionProgressText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private var characterPicker: some View {
        HStack(spacing: 6) {
            ForEach(CharacterType.allCases, id: \.storedValue) { character in
                Button {
                    selectedCharacterFamilyValue = character.storedValue
                } label: {
                    CharacterView(
                        character: character,
                        expression: .idle,
                        cloudColor: selectedCloudColor,
                        isLocked: false
                    )
                    .frame(width: 26, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                selectedCharacterFamily == character ? Color.primary : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sliderRow(
        title: String,
        suffix: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(suffix.isEmpty ? "\(value.wrappedValue)" : "\(value.wrappedValue) \(suffix)")
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
        }
    }

    private var primaryActionTitle: String {
        switch vm.state {
        case .idle:
            return "start"
        case .focusRunning, .breakRunning:
            return vm.isPaused ? "go!" : "pause"
        case .waitingForBreakConfirmation, .overdueBreak:
            return "start"
        case .waitingForWorkConfirmation, .overdueWork:
            return "go!"
        }
    }

    private func handlePrimaryAction() {
        switch vm.state {
        case .idle:
            vm.startWork()
        case .focusRunning, .breakRunning:
            if vm.isPaused {
                vm.continuePausedSession()
            } else {
                vm.pauseCurrentSession()
            }
        case .waitingForBreakConfirmation, .overdueBreak:
            vm.startBreak()
        case .waitingForWorkConfirmation, .overdueWork:
            vm.resumeWork()
        }
    }
}

struct ProSessionSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("close pro settings")
            }

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
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("close paywall")
            }

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

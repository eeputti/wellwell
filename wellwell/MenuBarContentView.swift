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
                    Button(L10n.tr("settings")) {
                        showSettings = true
                    }
                    Button(L10n.tr("stats")) {
                        showStats = true
                    }
                    Divider()
                    Button(L10n.tr("open_main_window")) {
                        openWindow(id: "main")
                    }
                    if vm.state != .idle {
                        Button(L10n.tr("reset_timer")) {
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
                    Text(L10n.tr("cloud_color"))
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
                    Text(L10n.tr("nice_work"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.tr("today_sessions_minutes", vm.todaySessionCount, vm.todayFocusMinutes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(L10n.tr("take_earned_break"))
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
                Button(L10n.tr("start_focus")) {
                    vm.startWork()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
                Button(L10n.tr("take_earned_break")) {
                    vm.startBreak()
                }
                .buttonStyle(.borderedProminent)

                Button(L10n.tr("continue_session_risk")) {
                    vm.startWork()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .focusRunning {
                Button(L10n.tr("take_earned_break")) {
                    vm.startBreak()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .breakRunning {
                Button(L10n.tr("skip_break")) {
                    vm.resumeWork()
                }
                .buttonStyle(.bordered)
            }

            if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
                Button(L10n.tr("sorry_late")) {
                    vm.resumeWork()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state != .idle {
                Button(L10n.tr("reset_timer")) {
                    vm.resetTimer()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Button(L10n.tr("open_main_window")) {
                openWindow(id: "main")
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button(L10n.tr("quit_wellwell")) {
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
            return vm.hasCompletedSessionToday ? L10n.tr("status_you_showed_up") : L10n.tr("status_ready_when_you_are")
        case .focusRunning:
            return L10n.tr("status_work_in_progress")
        case .waitingForBreakConfirmation:
            return L10n.tr("status_time_for_break", vm.upcomingBreakLabel)
        case .breakRunning:
            return L10n.tr("status_break_session", vm.upcomingBreakLabel)
        case .waitingForWorkConfirmation:
            return L10n.tr("status_good_to_go_again")
        case .overdueBreak:
            return L10n.tr("status_gentle_break_reminder")
        case .overdueWork:
            return L10n.tr("status_restart_gently")
        }
    }

    private var bubbleText: String {
        switch vm.state {
        case .idle:
            return vm.todaySessionCount == 0 ? L10n.tr("bubble_ready") : L10n.tr("bubble_one_block_enough")
        case .focusRunning:
            return L10n.tr("bubble_keep_up")
        case .waitingForBreakConfirmation:
            return L10n.tr("status_time_for_break", vm.upcomingBreakLabel)
        case .breakRunning:
            return L10n.tr("bubble_break_time")
        case .waitingForWorkConfirmation:
            return L10n.tr("bubble_come_back")
        case .overdueBreak:
            return L10n.tr("bubble_break_time")
        case .overdueWork:
            return L10n.tr("bubble_come_back")
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
            sliderRow(title: L10n.tr("focus_short"), suffix: L10n.tr("min"), value: $vm.focusMinutes, range: 1...120)
            sliderRow(title: L10n.tr("break_short"), suffix: L10n.tr("min"), value: $vm.breakMinutes, range: 1...60)
            sliderRow(title: L10n.tr("sessions_short"), suffix: "", value: $vm.sessionsUntilLongBreak, range: 1...12)
            sliderRow(title: L10n.tr("long_break"), suffix: L10n.tr("min"), value: $vm.longBreakMinutes, range: 1...90)
            Text(L10n.tr("progress", vm.completedSessionProgressText))
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
            return L10n.tr("start")
        case .focusRunning, .breakRunning:
            return vm.isPaused ? L10n.tr("go") : L10n.tr("pause")
        case .waitingForBreakConfirmation, .overdueBreak:
            return L10n.tr("start")
        case .waitingForWorkConfirmation, .overdueWork:
            return L10n.tr("go")
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
                .accessibilityLabel(L10n.tr("close_pro_settings"))
            }

            Text(L10n.tr("pro_title"))
                .font(.title2.weight(.semibold))
            Text(L10n.tr("pro_customize"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Text(L10n.tr("focus_short"))
                Spacer()
                TextField("25", value: $vm.focusMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text(L10n.tr("min"))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(L10n.tr("break_short"))
                Spacer()
                TextField("5", value: $vm.breakMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text(L10n.tr("min"))
                    .foregroundStyle(.secondary)
            }

            Button(L10n.tr("done")) {
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
                .accessibilityLabel(L10n.tr("close_paywall"))
            }

            Image("well_idle")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 80)

            Text(L10n.tr("unlock_pro"))
                .font(.title2.weight(.semibold))

            Text(L10n.tr("pro_pitch"))
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
                    Text(L10n.tr("adopt_cloud_pro"))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchaseManager.isPurchasing)

            Button(L10n.tr("restore_purchase")) {
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

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
    @AppStorage("selectedCharacterFamily") private var selectedCharacterFamilyValue = CharacterType.cloud.storedValue
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @State private var showPaywall = false
    @State private var showProSettings = false

    var body: some View {
        VStack(spacing: 14) {
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
            
            if vm.state == .idle {
                settingsPanel
            }
            
            
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
            return "time for a \(vm.upcomingBreakLabel)"
        case .breakRunning:
            return "\(vm.upcomingBreakLabel) session"
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
            return "time for a \(vm.upcomingBreakLabel)"
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
            characterPicker
            cloudColorPicker
            if purchaseManager.isPro {
                Button("pro settings") {
                    showProSettings = true
                }
                .buttonStyle(.bordered)
            } else {
                Button("unlock pro") {
                    showPaywall = true
                }
                .buttonStyle(.borderedProminent)
            }
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

    private var cloudColorPicker: some View {
        HStack(spacing: 8) {
            ForEach(CloudColor.allCases, id: \.storedValue) { color in
                Button {
                    selectedCloudColorValue = color.storedValue
                } label: {
                    Circle()
                        .fill(swatchColor(for: color))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCloudColor == color ? Color.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func swatchColor(for color: CloudColor) -> Color {
        switch color {
        case .default:
            return Color.white
        case .blue:
            return Color(red: 0.43, green: 0.69, blue: 0.97)
        case .green:
            return Color(red: 0.46, green: 0.81, blue: 0.59)
        case .pink:
            return Color(red: 0.95, green: 0.58, blue: 0.75)
        case .red:
            return Color(red: 0.95, green: 0.43, blue: 0.43)
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

import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @AppStorage("autoStartNextSession") private var autoStartNextSession = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("weeklySummaryConsent") private var weeklySummaryConsent = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("timer") {
                    Stepper(value: $vm.focusMinutes, in: 1...120) {
                        settingsRow("focus duration", value: "\(vm.focusMinutes) min")
                    }

                    Stepper(value: $vm.breakMinutes, in: 1...60) {
                        settingsRow("short break duration", value: "\(vm.breakMinutes) min")
                    }

                    Stepper(value: $vm.longBreakMinutes, in: 1...90) {
                        settingsRow("long break duration", value: "\(vm.longBreakMinutes) min")
                    }

                    Stepper(value: $vm.sessionsUntilLongBreak, in: 1...12) {
                        settingsRow("sessions before long break", value: "\(vm.sessionsUntilLongBreak)")
                    }
                }

                Section("behavior") {
                    Toggle("auto-start next session", isOn: $autoStartNextSession)
                    Toggle("sound (placeholder)", isOn: $soundEnabled)
                    Toggle("notifications (placeholder)", isOn: $notificationsEnabled)

                    if !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Toggle("weekly summary email", isOn: $weeklySummaryConsent)
                    }
                }

                Section("cloud") {
                    HStack(spacing: 10) {
                        ForEach(CloudColor.allCases, id: \.storedValue) { color in
                            Button {
                                selectedCloudColorValue = color.storedValue
                            } label: {
                                Circle()
                                    .fill(swatchColor(for: color))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedCloudColorValue == color.storedValue ? Color.primary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("close settings")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private func settingsRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
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
}

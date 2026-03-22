import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @AppStorage("autoStartNextSession") private var autoStartNextSession = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
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
                }
            }
            .navigationTitle("settings")
            .toolbar {
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
}

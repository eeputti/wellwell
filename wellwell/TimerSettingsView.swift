import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("autoStartNextSession") private var autoStartNextSession = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("weeklySummaryConsent") private var weeklySummaryConsent = false
    @AppStorage("preferredLanguage") private var preferredLanguage = AppLanguage.english.rawValue
    @AppStorage(TimerViewModel.dailyFocusTargetMinutesKey) private var dailyFocusTargetMinutes = 120

    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    private let allowedDailyGoalOptions = [60, 120, 180]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("your settings")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("shape your focus experience")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    timerSection
                    accountSection
                    appSection

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 22)
            .accessibilityLabel("close settings")
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(purchaseManager)
        }
        .onAppear {
            normalizeDailyFocusGoalIfNeeded()
        }
        .environment(\.colorScheme, .light)
    }

    private var timerSection: some View {
        sectionCard(title: "timer", subtitle: "adjust your flow first") {
            VStack(spacing: 12) {
                sliderRow(title: "focus duration", suffix: "min", value: $vm.focusMinutes, range: 1...120)
                sliderRow(title: "short break", suffix: "min", value: $vm.breakMinutes, range: 1...60)
                sliderRow(title: "sessions before long break", suffix: "", value: $vm.sessionsUntilLongBreak, range: 1...12)
                sliderRow(title: "long break", suffix: "min", value: $vm.longBreakMinutes, range: 1...90)
                VStack(alignment: .leading, spacing: 6) {
                    Text("daily focus progress goal")
                        .foregroundStyle(.primary)
                    Picker("daily focus progress goal", selection: $dailyFocusTargetMinutes) {
                        ForEach(allowedDailyGoalOptions, id: \.self) { option in
                            Text("\(option) min").tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Toggle("auto-start next session", isOn: $autoStartNextSession)
            }
        }
    }

    private func normalizeDailyFocusGoalIfNeeded() {
        guard allowedDailyGoalOptions.contains(dailyFocusTargetMinutes) else {
            dailyFocusTargetMinutes = 120
            return
        }
    }

    private var accountSection: some View {
        sectionCard(title: "account profile", subtitle: "name, email and plan") {
            VStack(spacing: 12) {
                textRow(title: "your name") {
                    TextField("your name", text: $userFirstName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }

                textRow(title: "email") {
                    TextField("email", text: $userEmail)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }

                if !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Toggle("weekly summary email", isOn: $weeklySummaryConsent)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchaseManager.isPro ? "wellwell pro active" : "free plan")
                            .font(.subheadline.weight(.semibold))
                        Text(purchaseManager.isPro ? "thanks for supporting wellwell" : "upgrade for more personalization")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !purchaseManager.isPro {
                        Button("upgrade to pro") {
                            showPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var appSection: some View {
        sectionCard(title: "app settings", subtitle: "language, sounds and look") {
            VStack(spacing: 12) {
                Picker("language", selection: $preferredLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("sound", isOn: $soundEnabled)
                Toggle("notifications", isOn: $notificationsEnabled)

                VStack(alignment: .leading, spacing: 8) {
                    Text("cloud color")
                        .font(.subheadline.weight(.medium))
                    CharacterColorPickerView(selectedCloudColorValue: $selectedCloudColorValue)
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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
                    .foregroundStyle(.primary)
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

    private func textRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .foregroundStyle(.primary)
                .frame(width: 90, alignment: .leading)
            content()
            Spacer()
        }
    }

}

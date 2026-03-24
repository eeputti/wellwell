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

    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    timerSection
                    accountSection
                    appSection
                }
                .padding(20)
            }
            .navigationTitle(L10n.tr("settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("done")) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 560)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(purchaseManager)
        }
    }

    private var timerSection: some View {
        sectionCard(title: L10n.tr("timer"), subtitle: L10n.tr("adjust_flow")) {
            VStack(spacing: 12) {
                sliderRow(title: L10n.tr("focus_duration"), suffix: L10n.tr("min"), value: $vm.focusMinutes, range: 1...120)
                sliderRow(title: L10n.tr("short_break"), suffix: L10n.tr("min"), value: $vm.breakMinutes, range: 1...60)
                sliderRow(title: L10n.tr("sessions_before_long_break"), suffix: "", value: $vm.sessionsUntilLongBreak, range: 1...12)
                sliderRow(title: L10n.tr("long_break"), suffix: L10n.tr("min"), value: $vm.longBreakMinutes, range: 1...90)
                Toggle(L10n.tr("auto_start_next_session"), isOn: $autoStartNextSession)
            }
        }
    }

    private var accountSection: some View {
        sectionCard(title: L10n.tr("account_profile"), subtitle: L10n.tr("name_email_plan")) {
            VStack(spacing: 12) {
                textRow(title: L10n.tr("your_name")) {
                    TextField(L10n.tr("your_name"), text: $userFirstName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }

                textRow(title: L10n.tr("email")) {
                    TextField(L10n.tr("email"), text: $userEmail)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }

                if !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Toggle(L10n.tr("weekly_summary_email"), isOn: $weeklySummaryConsent)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchaseManager.isPro ? L10n.tr("wellwell_pro_active") : L10n.tr("free_plan"))
                            .font(.subheadline.weight(.semibold))
                        Text(purchaseManager.isPro ? L10n.tr("thanks_supporting") : L10n.tr("upgrade_more_personalization"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !purchaseManager.isPro {
                        Button(L10n.tr("upgrade_to_pro")) {
                            showPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var appSection: some View {
        sectionCard(title: L10n.tr("app_settings"), subtitle: L10n.tr("language_sounds_look")) {
            VStack(spacing: 12) {
                Picker(L10n.tr("language"), selection: $preferredLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(L10n.tr("sound"), isOn: $soundEnabled)
                Toggle(L10n.tr("notifications"), isOn: $notificationsEnabled)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("cloud_color"))
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
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.05))
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
                .frame(width: 90, alignment: .leading)
            content()
            Spacer()
        }
    }
}

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("weeklySummaryConsent") private var weeklySummaryConsent = false

    @State private var firstNameInput = ""
    @State private var emailInput = ""
    @State private var consent = false

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("welcome to wellwell")
                    .font(.title2.weight(.semibold))
                Text("a calm little focus space with your cloud companion")
                    .foregroundStyle(.secondary)

                TextField("first name", text: $firstNameInput)
                    .textFieldStyle(.roundedBorder)

                TextField("email (optional)", text: $emailInput)
                    .textFieldStyle(.roundedBorder)

                Toggle("send me weekly summaries and updates", isOn: $consent)

                Button("continue") {
                    save()
                }
                .buttonStyle(MainButtonStyle())
                .disabled(firstNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(26)
            .frame(width: 460)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.86))
            )
        }
    }

    private func save() {
        let cleanName = firstNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        userFirstName = cleanName
        userEmail = cleanEmail
        weeklySummaryConsent = !cleanEmail.isEmpty ? consent : false
        hasCompletedOnboarding = true
    }
}

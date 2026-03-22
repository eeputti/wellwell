import SwiftUI

struct IdleUtilityPanelView: View {
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue

    let onStatsTap: () -> Void
    let onSettingsTap: () -> Void
    let onHistoryTap: () -> Void

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quick tools")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black.opacity(0.65))

            HStack(spacing: 10) {
                Text("choose your cloud")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.65))

                Spacer(minLength: 8)

                HStack(spacing: 8) {
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
                                            selectedCloudColor == color ? Color.black.opacity(0.75) : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 8) {
                utilityButton(title: "stats", action: onStatsTap)
                utilityButton(title: "settings", action: onSettingsTap)
                utilityButton(title: "history", action: onHistoryTap)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.84))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .frame(maxWidth: 380)
    }

    private func utilityButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.black.opacity(0.78))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.95, green: 0.92, blue: 0.84))
        )
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

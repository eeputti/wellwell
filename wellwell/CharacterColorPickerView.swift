import SwiftUI

struct CharacterColorPickerView: View {
    @Binding var selectedCloudColorValue: String
    var swatchSize: CGFloat = 26
    var spacing: CGFloat = 10
    var selectedBorderColor: Color = .primary
    var unselectedBorderColor: Color = .clear

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("choose your cloud")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: spacing) {
                ForEach(CloudColor.allCases, id: \.storedValue) { color in
                    let isSelected = selectedCloudColor == color

                    Button {
                        selectedCloudColorValue = color.storedValue
                    } label: {
                        Circle()
                            .fill(swatchColor(for: color))
                            .frame(width: swatchSize, height: swatchSize)
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? selectedBorderColor : unselectedBorderColor,
                                        lineWidth: isSelected ? 2.5 : 1
                                    )
                            )
                            .scaleEffect(isSelected ? 1.08 : 1)
                            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selectedCloudColorValue)
                    }
                    .buttonStyle(.plain)
                }
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
}

import SwiftUI

struct CharacterColorPickerView: View {
    @Binding var selectedCloudColorValue: String
    var swatchSize: CGFloat = 20
    var spacing: CGFloat = 10
    var selectedBorderColor: Color = .primary
    var unselectedBorderColor: Color = .clear

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(CloudColor.allCases, id: \.storedValue) { color in
                Button {
                    selectedCloudColorValue = color.storedValue
                } label: {
                    Circle()
                        .fill(swatchColor(for: color))
                        .frame(width: swatchSize, height: swatchSize)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCloudColor == color ? selectedBorderColor : unselectedBorderColor,
                                    lineWidth: 2
                                )
                        )
                        .overlay {
                            if color.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: swatchSize * 0.45, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .opacity(color.isPremium ? 0.65 : 1)
                }
                .buttonStyle(.plain)
                .disabled(color.isPremium)
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

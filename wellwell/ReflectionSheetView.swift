import SwiftUI

struct ReflectionSheetView: View {
    let onSave: (String, Int) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workText = ""
    @State private var focusScore = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("quick reflection") {
                    TextField("what did you get done? (optional)", text: $workText, axis: .vertical)
                        .lineLimit(2...4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("how focused did it feel?")
                            .font(.subheadline.weight(.medium))
                        Picker("focus score", selection: $focusScore) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                            Text("4").tag(4)
                            Text("5").tag(5)
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Text("hard to focus")
                            Spacer()
                            Text("fully focused")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("that counted")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("skip") {
                        onSkip()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(workText, focusScore)
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 300)
    }
}

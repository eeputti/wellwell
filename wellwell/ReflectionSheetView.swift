import SwiftUI

struct ReflectionSheetView: View {
    let onSave: (String, ReflectionProductivity, Int?) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workText = ""
    @State private var productivity: ReflectionProductivity = .okay
    @State private var feeling = 2
    @State private var includeFeeling = false

    var body: some View {
        NavigationStack {
            Form {
                Section("quick reflection") {
                    TextField("what did you focus on?", text: $workText)

                    Picker("how did it feel?", selection: $productivity) {
                        ForEach(ReflectionProductivity.allCases) { value in
                            Text(value.label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("add a quick feeling check", isOn: $includeFeeling)
                    if includeFeeling {
                        Picker("feeling", selection: $feeling) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("that counted")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSkip()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("close reflection")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("skip") {
                        onSkip()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(workText, productivity, includeFeeling ? feeling : nil)
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 300)
    }
}

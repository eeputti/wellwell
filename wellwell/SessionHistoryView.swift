import SwiftUI

struct SessionHistoryView: View {
    let sessions: [SessionRecord]
    @Environment(\.dismiss) private var dismiss

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "no sessions yet",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Complete a focus session to start building your recent history.")
                    )
                } else {
                    List(sessions.indices, id: \.self) { index in
                        let session = sessions[index]
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.type.title)
                                .font(.headline)
                            Text(formatter.string(from: session.completedAt))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(session.durationMinutes) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("recent sessions")
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
}

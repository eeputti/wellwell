import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let completedAt: Date
    let focusMinutes: Int
    let sessionLabel: String
    let wasLongBreakSession: Bool

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        focusMinutes: Int,
        sessionLabel: String,
        wasLongBreakSession: Bool
    ) {
        self.id = id
        self.completedAt = completedAt
        self.focusMinutes = focusMinutes
        self.sessionLabel = sessionLabel
        self.wasLongBreakSession = wasLongBreakSession
    }
}

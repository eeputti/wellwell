import Foundation

enum SessionRecordType: String, Codable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus:
            return "focus"
        case .shortBreak:
            return "short break"
        case .longBreak:
            return "long break"
        }
    }
}

struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let completedAt: Date
    let type: SessionRecordType
    let durationMinutes: Int

    init(id: UUID = UUID(), completedAt: Date = Date(), type: SessionRecordType, durationMinutes: Int) {
        self.id = id
        self.completedAt = completedAt
        self.type = type
        self.durationMinutes = max(1, durationMinutes)
    }
}

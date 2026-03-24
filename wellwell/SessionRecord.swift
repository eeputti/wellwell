//
//  SessionRecord.swift
//  wellwell
//
//  Created by Eelis Puro on 22.3.2026.
//

import Foundation

struct SessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let completedAt: Date
    let focusSeconds: Int
    var intention: String?
    var reflectionWorkSummary: String?
    var reflectionProductivity: ReflectionProductivity?
    var reflectionFeeling: Int?
    var reflectionFocusScore: Int?
    var sessionType: SessionType?
    var focusNote: String?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        focusSeconds: Int,
        intention: String? = nil,
        reflectionWorkSummary: String? = nil,
        reflectionProductivity: ReflectionProductivity? = nil,
        reflectionFeeling: Int? = nil,
        reflectionFocusScore: Int? = nil,
        sessionType: SessionType? = nil,
        focusNote: String? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.focusSeconds = max(60, focusSeconds)
        self.intention = intention?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.reflectionWorkSummary = reflectionWorkSummary
        self.reflectionProductivity = reflectionProductivity
        self.reflectionFeeling = reflectionFeeling
        if let reflectionFocusScore {
            self.reflectionFocusScore = min(max(reflectionFocusScore, 1), 5)
        } else {
            self.reflectionFocusScore = nil
        }
        self.sessionType = sessionType
        let trimmedFocusNote = focusNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.focusNote = trimmedFocusNote?.isEmpty == true ? nil : trimmedFocusNote
    }
}

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case work
    case study
    case read
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .work:
            return "work"
        case .study:
            return "study"
        case .read:
            return "read"
        case .other:
            return "other"
        }
    }
}

enum ReflectionProductivity: String, Codable, CaseIterable, Identifiable {
    case low
    case okay
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low:
            return "not really"
        case .okay:
            return "kind of"
        case .high:
            return "yes"
        }
    }
}

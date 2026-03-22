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
    var reflectionWorkSummary: String?
    var reflectionProductivity: ReflectionProductivity?
    var reflectionFeeling: Int?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        focusSeconds: Int,
        reflectionWorkSummary: String? = nil,
        reflectionProductivity: ReflectionProductivity? = nil,
        reflectionFeeling: Int? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.focusSeconds = max(60, focusSeconds)
        self.reflectionWorkSummary = reflectionWorkSummary
        self.reflectionProductivity = reflectionProductivity
        self.reflectionFeeling = reflectionFeeling
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

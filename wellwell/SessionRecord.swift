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

    init(id: UUID = UUID(), completedAt: Date = Date(), focusSeconds: Int) {
        self.id = id
        self.completedAt = completedAt
        self.focusSeconds = max(60, focusSeconds)
    }
}

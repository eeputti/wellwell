//
//  CharacterType.swift
//  wellwell
//
//  Created by Eelis Puro on 21.3.2026.
//

import Foundation

enum CharacterType: CaseIterable {
    case cloud
    case star
    case moon
    case rainCloud
    case rainbow
    case leaf

    func assetName(for expression: ExpressionType) -> String {
        "\(prefix)_\(suffix(for: expression))"
    }

    private var prefix: String {
        switch self {
        case .cloud:
            return "cloud"
        case .star:
            return "star"
        case .moon:
            return "moon"
        case .rainCloud:
            return "rainCloud"
        case .rainbow:
            return "rainbow"
        case .leaf:
            return "leaf"
        }
    }

    private func suffix(for expression: ExpressionType) -> String {
        switch expression {
        case .idle:
            return "idle"
        case .focus:
            return "focus"
        case .shortBreak:
            return "shortBreak"
        case .longBreak:
            return "longBreak"
        case .breakStarting:
            return "breakStarting"
        case .noBreakWarning:
            return "noBreakWarning"
        }
    }
}

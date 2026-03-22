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

    var storedValue: String {
        switch self {
        case .cloud: return "cloud"
        case .star: return "star"
        case .moon: return "moon"
        case .rainCloud: return "rainCloud"
        case .rainbow: return "rainbow"
        case .leaf: return "leaf"
        }
    }

    init(storedValue: String) {
        switch storedValue {
        case "cloud": self = .cloud
        case "star": self = .star
        case "moon": self = .moon
        case "rainCloud": self = .rainCloud
        case "rainbow": self = .rainbow
        case "leaf": self = .leaf
        default: self = .cloud
        }
    }

    func assetName(for expression: ExpressionType) -> String {
        switch expression {
        case .idle:
            return "well_idle"
        case .focus:
            return "well_focus"
        case .shortBreak:
            return "well_break"
        case .longBreak:
            return "well_sleep"
        case .breakStarting:
            return "well_break_alert"
        case .noBreakWarning:
            return "well_angry"
        }
    }
}

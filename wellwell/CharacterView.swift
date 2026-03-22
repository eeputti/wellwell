//
//  CharacterView.swift
//  wellwell
//
//  Created by Eelis Puro on 21.3.2026.
//

import SwiftUI

struct CharacterView: View {
    let character: CharacterType
    let expression: ExpressionType
    let cloudColor: CloudColor?
    let isLocked: Bool
    var onLockedTap: (() -> Void)? = nil

    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @State private var floatUp = false

    init(
        character: CharacterType,
        expression: ExpressionType,
        cloudColor: CloudColor? = nil,
        isLocked: Bool,
        onLockedTap: (() -> Void)? = nil
    ) {
        self.character = character
        self.expression = expression
        self.cloudColor = cloudColor
        self.isLocked = isLocked
        self.onLockedTap = onLockedTap
    }

    private var expressionKey: String {
        String(describing: expression).lowercased()
    }

    private var resolvedCloudColor: CloudColor {
        cloudColor ?? CloudColor(storedValue: selectedCloudColorValue)
    }

    private var imageName: String {
        character.assetName(for: expression, cloudColor: resolvedCloudColor)
    }

    private var isIdleExpression: Bool {
        expressionKey == "idle"
    }

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .id(imageName)
                .transition(.opacity)
        }
        .offset(y: isIdleExpression && !isLocked ? (floatUp ? -3 : 3) : 0)
        .grayscale(isLocked ? 1 : 0)
        .opacity(isLocked ? 0.82 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isLocked else { return }
            if let onLockedTap {
                onLockedTap()
            } else {
                print("CharacterView placeholder: locked character tapped")
            }
        }
        .onAppear {
            if isIdleExpression && !isLocked {
                floatUp = true
            }
        }
        .onChange(of: isIdleExpression) { _, newValue in
            floatUp = newValue && !isLocked
        }
        .onChange(of: isLocked) { _, newValue in
            if newValue {
                floatUp = false
            } else if isIdleExpression {
                floatUp = true
            }
        }
        .animation(.easeInOut(duration: 0.27), value: expressionKey)
        .animation(
            .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
            value: floatUp
        )
    }
}

enum CloudColorOption: String, CaseIterable, Identifiable {
    case defaultCloud
    case blue
    case green
    case pink
    case red

    var id: String { rawValue }

    var assetSuffix: String {
        switch self {
        case .defaultCloud: return "default"
        case .blue: return "blue"
        case .green: return "green"
        case .pink: return "pink"
        case .red: return "red"
        }
    }

    var color: Color {
        switch self {
        case .defaultCloud:
            return Color(red: 0.94, green: 0.79, blue: 0.39)
        case .blue:
            return Color(red: 0.51, green: 0.76, blue: 0.95)
        case .green:
            return Color(red: 0.56, green: 0.82, blue: 0.59)
        case .pink:
            return Color(red: 0.95, green: 0.67, blue: 0.82)
        case .red:
            return Color(red: 0.92, green: 0.52, blue: 0.51)
        }
    }

    var label: String {
        switch self {
        case .defaultCloud:
            return "gold"
        case .blue:
            return "blue"
        case .green:
            return "green"
        case .pink:
            return "pink"
        case .red:
            return "red"
        }
    }

    static func from(rawValue: String) -> CloudColorOption {
        CloudColorOption(rawValue: rawValue) ?? .defaultCloud
    }
}

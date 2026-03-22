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
    let isLocked: Bool
    var onLockedTap: (() -> Void)? = nil

    @State private var floatUp = false

    private var characterKey: String {
        String(describing: character).lowercased()
    }

    private var expressionKey: String {
        String(describing: expression).lowercased()
    }

    private var imageName: String {
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

    private var isIdleExpression: Bool {
        expressionKey == "idle"
    }

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .id(expressionKey)
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

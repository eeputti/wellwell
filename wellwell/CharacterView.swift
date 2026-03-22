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
    let cloudColor: CloudColor = .default
    let isLocked: Bool
    var onLockedTap: (() -> Void)? = nil

    @State private var floatUp = false

    private var expressionKey: String {
        String(describing: expression).lowercased()
    }

    private var imageName: String {
        character.assetName(for: expression, cloudColor: cloudColor)
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

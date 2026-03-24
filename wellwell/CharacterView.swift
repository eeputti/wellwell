//
//  CharacterView.swift
//  wellwell
//
//  Created by Eelis Puro on 21.3.2026.
//

import SwiftUI
import AppKit

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

    private var resolvedCloudColor: CloudColor {
        cloudColor ?? CloudColor(storedValue: selectedCloudColorValue)
    }

    private var imageName: String {
        character.assetName(for: expression, cloudColor: resolvedCloudColor)
    }

    private var renderableImageName: String? {
        let trimmed = imageName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, NSImage(named: trimmed) != nil {
            return trimmed
        }

        let fallback = "well_starter_idle_default"
        if NSImage(named: fallback) != nil {
            return fallback
        }

        return nil
    }

    var body: some View {
        ZStack {
            if let renderableImageName, let image = NSImage(named: renderableImageName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .offset(y: expression == .idle ? (floatUp ? -4 : 4) : 0)
                    .id(renderableImageName)
            }
        }
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
            floatUp = expression == .idle && !isLocked
        }
        .onChange(of: expression) { _, newValue in
            let isIdleExpression = newValue == .idle
            floatUp = isIdleExpression && !isLocked
        }
        .onChange(of: isLocked) { _, newValue in
            if newValue {
                floatUp = false
            } else if expression == .idle {
                floatUp = true
            }
        }
        .animation(.easeInOut(duration: 0.27), value: expression)
        .animation(
            expression == .idle
                ? .easeInOut(duration: 3).repeatForever(autoreverses: true)
                : .default,
            value: floatUp
        )
    }
}

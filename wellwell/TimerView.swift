//
//  TimerView.swift
//  wellwell
//
//  Created by Eelis Puro on 21.3.2026.
//

import SwiftUI

struct TimerView: View {
    enum Phase {
        case idle
        case focusing
        case shortBreak
        case longBreak
        case breakStarting
        case noBreakWarning
    }

    let sessionIndex: Int
    let totalSessions: Int
    let timeRemaining: Int
    let phase: Phase
    let onStart: () -> Void
    let onPause: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Session \(sessionIndex) of \(totalSessions)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.65))

                CharacterView(
                    character: .cloud,
                    expression: currentExpression,
                    isLocked: false
                )

                SpeechBubble(text: speechMessage)

                Text(formattedTime)
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black.opacity(0.85))

                HStack(spacing: 12) {
                    Button("Start") {
                        onStart()
                    }
                    .buttonStyle(TimerActionButtonStyle(backgroundColor: Color(red: 0.85, green: 0.93, blue: 0.82)))

                    Button("Pause") {
                        onPause()
                    }
                    .buttonStyle(TimerActionButtonStyle(backgroundColor: Color(red: 0.95, green: 0.91, blue: 0.78)))

                    Button("Skip") {
                        onSkip()
                    }
                    .buttonStyle(TimerActionButtonStyle(backgroundColor: Color(red: 0.93, green: 0.86, blue: 0.80)))
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 7)
            .frame(minWidth: 460, minHeight: 500)
            .padding(30)
        }
    }

    private var formattedTime: String {
        let safeSeconds = max(0, timeRemaining)
        let minutes = safeSeconds / 60
        let seconds = safeSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    private var currentExpression: ExpressionType {
        switch phase {
        case .idle:
            return .idle
        case .focusing:
            return .focus
        case .shortBreak:
            return .shortBreak
        case .longBreak:
            return .longBreak
        case .breakStarting:
            return .breakStarting
        case .noBreakWarning:
            return .noBreakWarning
        }
    }

    private var speechMessage: String {
        switch phase {
        case .idle:
            return "Ready when you are!"
        case .focusing:
            return "You've got this! Stay with me."
        case .shortBreak:
            return "Nice work! Take a breath."
        case .longBreak:
            return "Zzzz... wake me when you're back."
        case .breakStarting:
            return "Yay! Break time!!"
        case .noBreakWarning:
            return "Hey. You need a break. I'm serious."
        }
    }

    private var characterImageName: String {
        switch phase {
        case .idle:
            return "well_idle"
        case .focusing:
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

private struct CharacterImageView: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 220, height: 160)
            .padding(.vertical, 2)
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.96))
            )
            .overlay(
                SpeechBubbleTail()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: 22, height: 14)
                    .offset(y: 18),
                alignment: .bottom
            )
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
            .frame(maxWidth: 340)
            .padding(.bottom, 4)
    }
}

private struct SpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct TimerActionButtonStyle: ButtonStyle {
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black.opacity(0.84))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    TimerView(
        sessionIndex: 1,
        totalSessions: 4,
        timeRemaining: 25 * 60,
        phase: .idle,
        onStart: {},
        onPause: {},
        onSkip: {}
    )
}

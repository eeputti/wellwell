//
//  ContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("wellwell")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.opacity(0.7))

                SpeechBubbleView(text: bubbleText)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.25), value: bubbleText)
                Image(characterImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 160)

                Text(vm.formattedTime())
                    .font(.system(size: 80, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black.opacity(0.85))

                Text(statusText)
                    .font(.title3)
                    .foregroundStyle(.black.opacity(0.55))

                if vm.state == .idle {
                    Button("start work") {
                        vm.startWork()
                    }
                    .buttonStyle(MainButtonStyle())
                }

                if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
                    Button("start break") {
                        vm.startBreak()
                    }
                    .buttonStyle(MainButtonStyle())
                }

                if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
                    Button("resume work") {
                        vm.resumeWork()
                    }
                    .buttonStyle(MainButtonStyle())
                }
            }
            .frame(minWidth: 480, minHeight: 520)
            .padding(40)
        }
    }

    private var statusText: String {
        switch vm.state {
        case .idle:
            return "ready to start"
        case .focusRunning:
            return "focus session"
        case .waitingForBreakConfirmation:
            return "time for a break"
        case .breakRunning:
            return "break session"
        case .waitingForWorkConfirmation:
            return "ready to continue?"
        case .overdueBreak:
            return "break overdue"
        case .overdueWork:
            return "work overdue"
        }
    }

    private var bubbleText: String {
        switch vm.state {
        case .idle:
            return "ready when you are"
        case .focusRunning:
            return "keep up the good work!"
        case .waitingForBreakConfirmation:
            return "time for a break"
        case .breakRunning:
            return "nice job. now, breathe a little"
        case .waitingForWorkConfirmation:
            return "ready to continue?"
        case .overdueBreak:
            return "why aren’t you on a break yet??"
        case .overdueWork:
            return "are you asleep? it’s been a long break"
        }
    }

    private var characterImageName: String {
        switch vm.state {
        case .idle:
            return "well_idle"
        case .focusRunning:
            return "well_focus"
        case .waitingForBreakConfirmation:
            return "well_break_alert"
        case .breakRunning:
            return "well_break"
        case .waitingForWorkConfirmation:
            return "well_focus"
        case .overdueBreak:
            return "well_angry"
        case .overdueWork:
            return "well_sleep"
        }
    }
}

struct SpeechBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundColor(.black.opacity(0.82))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.96))
            )
            .overlay(
                BubbleTail()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: 22, height: 14)
                    .offset(y: 18),
                alignment: .bottom
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
            .frame(maxWidth: 320)
            .padding(.bottom, 4)
    }
}
struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.94, green: 0.79, blue: 0.39))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    ContentView()
}

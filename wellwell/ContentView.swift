//
//  ContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TimerViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("wellwell")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.opacity(0.7))

                Circle()
                    .fill(Color(red: 0.94, green: 0.79, blue: 0.39))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Text(faceText)
                            .font(.system(size: 56))
                    )

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

                if vm.state == .waitingForBreakConfirmation {
                    Button("start break") {
                        vm.startBreak()
                    }
                    .buttonStyle(MainButtonStyle())
                }

                if vm.state == .waitingForWorkConfirmation {
                    Button("resume work") {
                        vm.resumeWork()
                    }
                    .buttonStyle(MainButtonStyle())
                }
            }
            .frame(minWidth: 480, minHeight: 420)
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
        }
    }

    private var faceText: String {
        switch vm.state {
        case .idle:
            return "🙂"
        case .focusRunning:
            return "😌"
        case .waitingForBreakConfirmation:
            return "👉"
        case .breakRunning:
            return "🌼"
        case .waitingForWorkConfirmation:
            return "👀"
        }
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

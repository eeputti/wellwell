//
//  MenuBarContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//



import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            Image(characterImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 90)

            Text(vm.formattedTime())
                .font(.system(size: 34, weight: .light, design: .rounded))
                .monospacedDigit()

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                HStack {
                    Text("focus")
                    Spacer()
                    TextField("25", value: $vm.focusMinutes, format: .number)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("min")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("break")
                    Spacer()
                    TextField("5", value: $vm.breakMinutes, format: .number)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("min")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            
            
            Text(bubbleText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)

            if vm.state == .idle {
                Button("start work") {
                    vm.startWork()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
                Button("start break") {
                    vm.startBreak()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
                Button("resume work") {
                    vm.resumeWork()
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            Button("open main window") {
                openWindow(id: "main")
            }

            Button("quit wellwell") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 280)
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
            return "i'm ready when you are"
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

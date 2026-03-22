//
//  ContentView.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel
    @AppStorage("selectedCharacterFamily") private var selectedCharacterFamilyValue = CharacterType.cloud.storedValue
    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("wellwell")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.opacity(0.7))

                if vm.showStreakReaction {
                    StreakReactionView(streakDays: vm.streakDays, mood: vm.streakMood)
                        .transition(.opacity.combined(with: .scale))
                }

                SpeechBubbleView(text: bubbleText)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.25), value: bubbleText)
                CharacterView(
                    character: selectedCharacterFamily,
                    expression: currentExpression,
                    cloudColor: selectedCloudColor,
                    isLocked: false
                )
                    .frame(width: 220, height: 160)

                Text(vm.formattedTime())
                    .font(.system(size: 80, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black.opacity(0.85))

                Text(statusText)
                    .font(.title3)
                    .foregroundStyle(.black.opacity(0.55))

                if vm.state == .idle {
                    settingsPanel

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

                if vm.state != .idle {
                    Button("reset timer") {
                        vm.resetTimer()
                    }
                    .buttonStyle(MainButtonStyle())
                }
            }
            .frame(minWidth: 480, minHeight: 520)
            .padding(40)
        }
        .onAppear {
            vm.triggerOpeningReaction()
        }
        .animation(.easeInOut(duration: 0.25), value: vm.showStreakReaction)
    }

    private var statusText: String {
        switch vm.state {
        case .idle:
            return "ready to start"
        case .focusRunning:
            return "focus session"
        case .waitingForBreakConfirmation:
            return "time for a \(vm.upcomingBreakLabel)"
        case .breakRunning:
            return "\(vm.upcomingBreakLabel) session"
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
            return "nice work. time for a \(vm.upcomingBreakLabel)"
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

    private var currentExpression: ExpressionType {
        switch vm.state {
        case .idle:
            return .idle
        case .focusRunning:
            return .focus
        case .waitingForBreakConfirmation:
            return .breakStarting
        case .breakRunning:
            return .shortBreak
        case .waitingForWorkConfirmation:
            return .focus
        case .overdueBreak:
            return .noBreakWarning
        case .overdueWork:
            return .longBreak
        }
    }

    private var selectedCharacterFamily: CharacterType {
        CharacterType(storedValue: selectedCharacterFamilyValue)
    }

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
    }

    private var cloudColorPicker: some View {
        HStack(spacing: 10) {
            ForEach(CloudColor.allCases, id: \.storedValue) { color in
                Button {
                    selectedCloudColorValue = color.storedValue
                } label: {
                    Circle()
                        .fill(swatchColor(for: color))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCloudColor == color ? Color.black.opacity(0.75) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func swatchColor(for color: CloudColor) -> Color {
        switch color {
        case .default:
            return Color.white
        case .blue:
            return Color(red: 0.43, green: 0.69, blue: 0.97)
        case .green:
            return Color(red: 0.46, green: 0.81, blue: 0.59)
        case .pink:
            return Color(red: 0.95, green: 0.58, blue: 0.75)
        case .red:
            return Color(red: 0.95, green: 0.43, blue: 0.43)
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 14) {
            timerSliderRow(
                title: "focus minutes",
                value: $vm.focusMinutes,
                range: 1...120
            )
            timerSliderRow(
                title: "break minutes",
                value: $vm.breakMinutes,
                range: 1...60
            )
            timerSliderRow(
                title: "sessions before long break",
                value: $vm.sessionsUntilLongBreak,
                range: 1...12
            )
            timerSliderRow(
                title: "long break minutes",
                value: $vm.longBreakMinutes,
                range: 1...90
            )

            Text("progress: \(vm.completedSessionProgressText)")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.6))

            cloudColorPicker
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.82))
        )
        .frame(maxWidth: 360)
    }

    private func timerSliderRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.7))
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.8))
            }

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(Color(red: 0.94, green: 0.79, blue: 0.39))
        }
    }
}

struct StreakReactionView: View {
    let streakDays: Int
    let mood: TimerViewModel.StreakMood

    @State private var floatUp = false
    @State private var pulse = false
    @State private var twinkle = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 48)
                    .overlay(goldenOverlay)
                    .scaleEffect(pulse ? 1.04 : 0.98)
                    .offset(y: floatUp ? -2 : 2)

                if mood == .golden {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.yellow.opacity(0.9))
                        .rotationEffect(.degrees(twinkle ? 8 : -8))
                        .scaleEffect(twinkle ? 1.15 : 0.9)
                        .offset(x: 6, y: -6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("streak: \(streakDays) day\(streakDays == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(reactionText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.85))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                floatUp.toggle()
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                twinkle.toggle()
            }
        }
    }

    @ViewBuilder
    private var goldenOverlay: some View {
        if mood == .golden {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.24), Color.orange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)
        }
    }

    private var mascotImageName: String {
        switch mood {
        case .sleepy:
            return "well_sleep"
        case .happy:
            return "well_idle"
        case .excited:
            return "well_break_alert"
        case .golden:
            return "well_idle"
        }
    }

    private var reactionText: String {
        switch mood {
        case .sleepy:
            return "shh... warming up ☁️"
        case .happy:
            return "yay, you’re on a roll!"
        case .excited:
            return "woah, amazing focus!"
        case .golden:
            return "golden cloud sighting ✨"
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

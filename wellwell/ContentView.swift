import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel

    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showStats = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                headerRow

                if vm.showStreakReaction {
                    StreakReactionView(streakDays: vm.streakDays, mood: vm.streakMood)
                        .transition(.opacity.combined(with: .scale))
                }

                cloudCard
                timerCard

                Spacer(minLength: 0)
            }
            .frame(minWidth: 640, minHeight: 620)
            .padding(30)
        }
        .onAppear {
            vm.triggerOpeningReaction()
        }
        .sheet(isPresented: $showStats) {
            StatsView()
                .environmentObject(vm)
        }
        .sheet(isPresented: $showSettings) {
            TimerSettingsView()
                .environmentObject(vm)
        }
        .sheet(
            isPresented: Binding(
                get: { vm.pendingReflectionSessionID != nil },
                set: { presented in
                    if !presented {
                        vm.skipReflection()
                    }
                }
            )
        ) {
            ReflectionSheetView(
                onSave: { work, productivity, feeling in
                    guard let sessionID = vm.pendingReflectionSessionID else { return }
                    vm.saveReflection(for: sessionID, workSummary: work, productivity: productivity, feeling: feeling)
                },
                onSkip: {
                    vm.skipReflection()
                }
            )
        }
        .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        .animation(.easeInOut(duration: 0.25), value: vm.showStreakReaction)
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.78))

                Text("let's make this one calm and focused")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 10) {
                Button("stats") {
                    showStats = true
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("settings") {
                    showSettings = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var cloudCard: some View {
        VStack(spacing: 14) {
            SpeechBubbleView(text: vm.state == .idle ? "hey, i’m ready when you are" : bubbleText)

            CharacterView(
                character: .cloud,
                expression: currentExpression,
                cloudColor: selectedCloudColor,
                isLocked: false
            )
            .frame(width: 260, height: 180)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.white.opacity(0.82))
        )
    }

    private var timerCard: some View {
        VStack(spacing: 12) {
            Text(vm.formattedTime())
                .font(.system(size: 80, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.84))

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.black.opacity(0.54))

            timerActionButtons
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.82))
        )
    }

    @ViewBuilder
    private var timerActionButtons: some View {
        if vm.state == .idle {
            Button("start the timer") {
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
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var greetingText: String {
        let name = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "welcome back" : "hi, \(name.lowercased())"
    }

    private var statusText: String {
        switch vm.state {
        case .idle:
            return "ready to begin"
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
            return "hey, i’m ready when you are"
        case .focusRunning:
            return "keep up the good work"
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

    private var selectedCloudColor: CloudColor {
        CloudColor(storedValue: selectedCloudColorValue)
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
            .frame(maxWidth: 340)
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

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black.opacity(0.8))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.82))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel

    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showStats = false
    @State private var showSettings = false
    @State private var showStartRitualOverlay = false
    @State private var isStartingSession = false

    var body: some View {
        GeometryReader { proxy in
            let isCompact = shouldUseCompactLayout(for: proxy.size)

            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.92)
                    .ignoresSafeArea()

                VStack(spacing: isCompact ? 14 : 22) {
                    if isCompact {
                        compactTopRow
                    } else {
                        headerRow
                    }

                    if vm.showStreakReaction && !isCompact {
                        StreakReactionView(
                            streakDays: vm.streakDays,
                            mood: vm.streakMood,
                            milestoneMessage: vm.streakMilestoneMessage
                        )
                            .transition(.opacity.combined(with: .scale))
                    }

                    if isCompact {
                        compactTimerCard
                    } else {
                        cloudCard
                        consistencyCard
                        timerCard
                        if vm.showPostSessionFlow && vm.state == .waitingForBreakConfirmation {
                            postSessionCard
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(minWidth: 340, minHeight: 290)
                .padding(isCompact ? 16 : 30)

                if showStartRitualOverlay {
                    StartRitualOverlay()
                        .transition(.opacity)
                }
            }
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
        .sheet(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        .animation(.easeInOut(duration: 0.25), value: vm.showStreakReaction)
        .animation(.easeInOut(duration: 0.25), value: showStartRitualOverlay)
    }

    private var compactTopRow: some View {
        HStack(alignment: .top, spacing: 10) {
            CharacterView(
                character: .cloud,
                expression: currentExpression,
                cloudColor: selectedCloudColor,
                isLocked: false
            )
            .frame(width: 72, height: 52)

            Spacer(minLength: 8)

            SpeechBubbleView(text: bubbleText, fontSize: 14, showTail: false)
                .frame(maxWidth: 190, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.78))

                Text("what a lovely day to work!")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 10) {
                Button("stats") {
                    showStats = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut("2", modifiers: [.command])

                Button("settings") {
                    showSettings = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }

    private var cloudCard: some View {
        VStack(spacing: 14) {
            SpeechBubbleView(text: bubbleText)

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

    private var consistencyCard: some View {
        HStack(spacing: 10) {
            Label {
                Text("\(vm.streakDays)-day streak")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: vm.streakDays >= 3 ? "flame.fill" : "flame")
                    .foregroundStyle(vm.streakDays >= 3 ? .orange : .secondary)
            }

            Spacer()

            Text("\(vm.todaySessionCount) today")
                .font(.caption.weight(.medium))
                .foregroundStyle(.black.opacity(0.58))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.06))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
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

            if !completionFeedbackLines.isEmpty {
                completionCard
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.82))
        )
    }

    private var compactTimerCard: some View {
        VStack(spacing: 12) {
            Text(vm.formattedTime())
                .font(.system(size: 70, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.84))

            Text(statusText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black.opacity(0.6))
                .multilineTextAlignment(.center)

            timerActionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
    }

    private var postSessionCard: some View {
        VStack(spacing: 10) {
            Text("nice work ✨")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.75))

            Text("today: \(vm.todaySessionCount) sessions • \(vm.todayFocusMinutes) min focus")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.55))

            Text("take an earned break")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.black.opacity(0.7))

            HStack(spacing: 10) {
                Button("take an earned break") {
                    vm.declineAnotherSession()
                }
                .buttonStyle(MainButtonStyle())

                Button("continue session at your own risk") {
                    vm.continueWithAnotherSession()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.82))
        )
    }

    @ViewBuilder
    private var timerActionButtons: some View {
        if vm.state == .idle {
            Button("let’s begin") {
                startSessionWithRitual()
            }
            .buttonStyle(MainButtonStyle())
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(isStartingSession)
        }

        if vm.state == .waitingForBreakConfirmation || vm.state == .overdueBreak {
            Button("take an earned break") {
                vm.startBreak()
            }
            .buttonStyle(MainButtonStyle())

            Button("continue session at your own risk") {
                vm.startWork()
            }
            .buttonStyle(SecondaryButtonStyle())
        }

        if vm.state == .waitingForWorkConfirmation || vm.state == .overdueWork {
            Button("sorry i'm late but good to go again!") {
                vm.resumeWork()
            }
            .buttonStyle(MainButtonStyle())
        }

        if vm.state == .breakRunning {
            Button("skip break") {
                vm.resumeWork()
            }
            .buttonStyle(SecondaryButtonStyle())
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
            return vm.hasCompletedSessionToday ? "you showed up today" : "ready when you are"
        case .focusRunning:
            return "work in progress"
        case .waitingForBreakConfirmation:
            return "nice work. \(vm.upcomingBreakLabel) next"
        case .breakRunning:
            return "\(vm.upcomingBreakLabel), then we can go again"
        case .waitingForWorkConfirmation:
            return "ready to continue?"
        case .overdueBreak:
            return "a short break still counts"
        case .overdueWork:
            return "restart gently"
        }
    }

    private var bubbleText: String {
        switch vm.state {
        case .idle:
            if vm.todaySessionCount == 0 {
                return "hey, i’m ready when you are"
            }
            if vm.streakDays >= 3 {
                return "you showed up today. quietly proud of you."
            }
            if vm.mostRecentReflectionProductivity == .low {
                return "it’s okay. a short session still counts."
            }
            return "ready for another gentle round?"
        case .focusRunning:
            return "keep up! you're doing great!"
        case .waitingForBreakConfirmation:
            return "nice work. that counted."
        case .breakRunning:
            return "whoa! it's break-time!"
        case .waitingForWorkConfirmation:
            return "come back, i miss you already."
        case .overdueBreak:
            return "whoa! it's break-time!"
        case .overdueWork:
            return "come back, i miss you already."
        }
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(completionFeedbackLines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.67))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.95, green: 0.98, blue: 0.93))
        )
    }

    private var completionFeedbackLines: [String] {
        guard vm.state == .waitingForBreakConfirmation || vm.state == .breakRunning else {
            return []
        }

        var lines: [String] = []
        if vm.todaySessionCount > 0 {
            lines.append("you’ve done \(vm.todaySessionCount) session\(vm.todaySessionCount == 1 ? "" : "s") today.")
        }
        if vm.todayFocusMinutes > 0 {
            lines.append("that’s \(formattedDuration(minutes: vm.todayFocusMinutes)) of focus.")
        }
        if vm.streakDays > 1 {
            lines.append("you’re on a \(vm.streakDays)-day streak.")
        }
        return Array(lines.prefix(2))
    }

    private func formattedDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 && remainder > 0 {
            return "\(hours)h \(remainder)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(remainder)m"
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

    private func shouldUseCompactLayout(for size: CGSize) -> Bool {
        size.width < 560 || size.height < 440
    }

    private func startSessionWithRitual() {
        guard !isStartingSession else { return }
        isStartingSession = true

        withAnimation(.easeInOut(duration: 0.25)) {
            showStartRitualOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showStartRitualOverlay = false
            }
            vm.startWork()
            isStartingSession = false
        }
    }
}

private struct StartRitualOverlay: View {
    var body: some View {
        Color.black.opacity(0.15)
            .ignoresSafeArea()
            .overlay {
                Text("take a breath")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.32))
                    )
            }
    }
}

struct StreakReactionView: View {
    let streakDays: Int
    let mood: TimerViewModel.StreakMood
    let milestoneMessage: String?

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
        if let milestoneMessage {
            return milestoneMessage
        }
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
    var fontSize: CGFloat = 18
    var showTail: Bool = true

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundColor(.black.opacity(0.82))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.96))
            )
            .overlay(alignment: .bottom) {
                if showTail {
                    BubbleTail()
                        .fill(Color.white.opacity(0.96))
                        .frame(width: 22, height: 14)
                        .offset(y: 18)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
            .frame(maxWidth: 340)
            .padding(.bottom, showTail ? 4 : 0)
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

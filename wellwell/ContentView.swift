import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel

    @AppStorage("selectedCloudColor") private var selectedCloudColorValue = CloudColor.default.storedValue
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(TimerViewModel.dailyFocusTargetMinutesKey) private var dailyFocusTargetMinutes = 120

    @State private var showStats = false
    @State private var showSettings = false
    @State private var showStartRitualOverlay = false
    @State private var isStartingSession = false

    var body: some View {
        GeometryReader { proxy in
            let isCompact = isCompactFocusMode(for: proxy.size)
            let uiScale = interfaceScale(for: proxy.size, compact: isCompact)

            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.92)
                    .ignoresSafeArea()

                VStack(spacing: scaled(isCompact ? 10 : 22, by: uiScale)) {
                    if isCompact {
                        compactFocusHeader(scale: uiScale)
                        Spacer(minLength: 0)
                    } else {
                        headerRow(scale: uiScale)
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
                        compactFocusCard(scale: uiScale)
                    } else {
                        heroRow(scale: uiScale)
                        consistencyCard(scale: uiScale)
                        if vm.showPostSessionFlow && vm.state == .waitingForBreakConfirmation {
                            postSessionCard(scale: uiScale)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(scaled(isCompact ? 12 : 30, by: uiScale))

                if showStartRitualOverlay {
                    StartRitualOverlay()
                        .transition(.opacity)
                }

                if let banner = vm.activeInAppBanner {
                    VStack {
                        inAppCompletionBanner(text: banner.text)
                            .padding(.top, scaled(isCompact ? 10 : 18, by: uiScale))
                        Spacer()
                    }
                    .padding(.horizontal, scaled(isCompact ? 12 : 22, by: uiScale))
                    .transition(.move(edge: .top).combined(with: .opacity))
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
                onSave: { work, focusScore, sessionType, focusNote in
                    guard let sessionID = vm.pendingReflectionSessionID else { return }
                    vm.saveReflection(
                        for: sessionID,
                        workSummary: work,
                        focusScore: focusScore,
                        sessionType: sessionType,
                        focusNote: focusNote
                    )
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
        .animation(.easeInOut(duration: 0.2), value: vm.activeInAppBanner)
    }

    private func inAppCompletionBanner(text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.black.opacity(0.72))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func compactFocusHeader(scale: CGFloat) -> some View {
        HStack(alignment: .top, spacing: scaled(12, by: scale)) {
            CharacterView(
                character: .cloud,
                expression: currentExpression,
                cloudColor: selectedCloudColor,
                isLocked: false
            )
            .frame(width: scaled(110, by: scale), height: scaled(80, by: scale))

            Spacer(minLength: scaled(10, by: scale))

            SpeechBubbleView(text: bubbleText, fontSize: scaled(14, by: scale), showTail: false)
                .frame(maxWidth: scaled(220, by: scale), alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, scaled(8, by: scale))
        .padding(.top, scaled(6, by: scale))
    }

    private func headerRow(scale: CGFloat) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: scaled(25, by: scale), weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.78))

                Text("what a lovely day to work!")
                    .font(.system(size: scaled(15, by: scale), weight: .regular, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
            }

            Spacer()

            HStack(spacing: scaled(10, by: scale)) {
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

    private func heroRow(scale: CGFloat) -> some View {
        HStack(alignment: .center, spacing: scaled(30, by: scale)) {
            VStack(spacing: scaled(10, by: scale)) {
                SpeechBubbleView(
                    text: bubbleText,
                    fontSize: scaled(16, by: scale),
                    showTail: false
                )
                .frame(maxWidth: scaled(280, by: scale))

                CharacterView(
                    character: .cloud,
                    expression: currentExpression,
                    cloudColor: selectedCloudColor,
                    isLocked: false
                )
                .frame(width: scaled(220, by: scale), height: scaled(150, by: scale))
            }
            .frame(maxWidth: scaled(300, by: scale), alignment: .top)

            timerCard(scale: scale)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, scaled(18, by: scale))
        .padding(.vertical, scaled(20, by: scale))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: scaled(26, by: scale))
                .fill(Color.white.opacity(0.82))
        )
    }

    private func consistencyCard(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: scaled(10, by: scale)) {
            HStack(spacing: scaled(10, by: scale)) {
                Label {
                    Text("\(vm.streakDays)-day streak")
                        .font(.system(size: scaled(15, by: scale), weight: .semibold, design: .rounded))
                } icon: {
                    Image(systemName: vm.streakDays >= 3 ? "flame.fill" : "flame")
                        .foregroundStyle(vm.streakDays >= 3 ? .orange : .secondary)
                }

                Spacer()

                Text("\(vm.todaySessionCount) today")
                    .font(.system(size: scaled(12, by: scale), weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .padding(.horizontal, scaled(10, by: scale))
                    .padding(.vertical, scaled(6, by: scale))
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.06))
                    )
            }

            VStack(alignment: .leading, spacing: scaled(8, by: scale)) {
                Text(consistencyHeadlineText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.64))

                progressRow(
                    title: "focus",
                    valueText: "\(vm.todayLiveFocusSeconds / 60) min",
                    progress: vm.todayFocusProgress(targetMinutes: dailyFocusTargetMinutes),
                    fillColor: Color(red: 0.94, green: 0.79, blue: 0.39).opacity(0.85),
                    scale: scale
                )

                let breakTargetMinutes = max(1, dailyFocusTargetMinutes * vm.breakMinutes / max(1, vm.focusMinutes))
                progressRow(
                    title: "break",
                    valueText: "\(vm.todayLiveBreakSeconds / 60) min",
                    progress: vm.todayBreakProgress(targetMinutes: breakTargetMinutes),
                    fillColor: Color(red: 0.62, green: 0.79, blue: 0.95).opacity(0.9),
                    scale: scale
                )

                progressRow(
                    title: "total",
                    valueText: "\(vm.todayTotalLiveWorkSeconds / 60) min",
                    progress: vm.todayTotalWorkProgress(targetMinutes: dailyFocusTargetMinutes + breakTargetMinutes),
                    fillColor: Color(red: 0.69, green: 0.89, blue: 0.76).opacity(0.92),
                    scale: scale
                )
            }
        }
        .padding(.horizontal, scaled(14, by: scale))
        .padding(.vertical, scaled(10, by: scale))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: scaled(16, by: scale))
                .fill(Color.white.opacity(0.82))
        )
    }

    private var consistencyHeadlineText: String {
        let targetSeconds = max(1, dailyFocusTargetMinutes) * 60
        if vm.todayLiveFocusSeconds >= targetSeconds {
            return "you're on fire!"
        }
        return vm.todayLiveFocusText()
    }

    private func progressRow(
        title: String,
        valueText: String,
        progress: Double,
        fillColor: Color,
        scale: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: scaled(4, by: scale)) {
            HStack {
                Text(title)
                    .font(.system(size: scaled(12, by: scale), weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))

                Spacer()

                Text(valueText)
                    .font(.system(size: scaled(12, by: scale), weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.07))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(fillColor)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: scaled(10, by: scale))
        }
    }

    private func timerCard(scale: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text(vm.formattedTime())
                .font(.system(size: scaled(80, by: scale), weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.84))

            Text(statusText)
                .font(.system(size: scaled(34, by: scale), weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.54))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            timerActionButtons

            if !completionFeedbackLines.isEmpty {
                completionCard
            }
        }
        .padding(.vertical, scaled(8, by: scale))
        .padding(.horizontal, scaled(6, by: scale))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func compactFocusCard(scale: CGFloat) -> some View {
        VStack(spacing: scaled(18, by: scale)) {
            Text(statusText)
                .font(.system(size: scaled(16, by: scale), weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)

            Text(vm.formattedTime())
                .font(.system(size: scaled(88, by: scale), weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            compactFocusActionButtons
        }
        .frame(maxWidth: scaled(360, by: scale))
        .frame(maxWidth: .infinity)
    }

    private func postSessionCard(scale: CGFloat) -> some View {
        VStack(spacing: scaled(10, by: scale)) {
            Text("nice work ✨")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.75))

            Text("today: \(vm.todaySessionCount) sessions • \(vm.todayFocusMinutes) min focus")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.55))

            Text("take an earned break")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.black.opacity(0.7))
        }
        .padding(scaled(18, by: scale))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: scaled(20, by: scale))
                .fill(Color.white.opacity(0.82))
        )
    }

    @ViewBuilder
    private var timerActionButtons: some View {
        if vm.state == .focusRunning || vm.state == .breakRunning {
            Button(vm.isPaused ? "go!" : "pause") {
                if vm.isPaused {
                    vm.continuePausedSession()
                } else {
                    vm.pauseCurrentSession()
                }
            }
            .buttonStyle(MainButtonStyle())
        }

        if vm.state == .focusRunning {
            Button("take an early break") {
                vm.startBreak(forceShortBreak: true)
            }
            .buttonStyle(SecondaryButtonStyle())
        }

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
            Button("i'm back again!") {
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

    @ViewBuilder
    private var compactFocusActionButtons: some View {
        switch vm.state {
        case .idle:
            Button("let’s begin!") {
                startSessionWithRitual()
            }
            .buttonStyle(MainButtonStyle())
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(isStartingSession)

        case .focusRunning, .breakRunning:
            Button(vm.isPaused ? "go!" : "pause") {
                if vm.isPaused {
                    vm.continuePausedSession()
                } else {
                    vm.pauseCurrentSession()
                }
            }
            .buttonStyle(MainButtonStyle())

            Button("skip session") {
                skipSessionFromCompactMode()
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!canSkipSessionInCompactMode)

        default:
            EmptyView()
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
                return "you showed up today. proud of you."
            }
            if let lastFocusScore = vm.mostRecentFocusScore, lastFocusScore <= 2 {
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

    private func interfaceScale(for size: CGSize, compact: Bool) -> CGFloat {
        let baseSize = compact ? CGSize(width: 560, height: 440) : CGSize(width: 900, height: 720)
        let widthScale = size.width / baseSize.width
        let heightScale = size.height / baseSize.height
        return min(max(min(widthScale, heightScale), 1.0), 1.35)
    }

    private func scaled(_ value: CGFloat, by scale: CGFloat) -> CGFloat {
        value * scale
    }

    private var canSkipSessionInCompactMode: Bool {
        switch vm.state {
        case .focusRunning, .waitingForBreakConfirmation, .overdueBreak, .breakRunning, .waitingForWorkConfirmation, .overdueWork:
            return true
        case .idle:
            return false
        }
    }

    private func skipSessionFromCompactMode() {
        switch vm.state {
        case .focusRunning:
            vm.startBreak(forceShortBreak: true)
        case .waitingForBreakConfirmation, .overdueBreak:
            vm.startBreak()
        case .breakRunning, .waitingForWorkConfirmation, .overdueWork:
            vm.resumeWork()
        case .idle:
            break
        }
    }

    private func isCompactFocusMode(for size: CGSize) -> Bool {
        let width = size.width
        let height = size.height
        let aspectRatio = width / max(height, 1)
        let smallWindow = width <= 620 || height <= 500
        let nearSquareWindow = width <= 700 && height <= 700 && aspectRatio <= 1.2
        return smallWindow || nearSquareWindow
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
            .lineLimit(2)
            .truncationMode(.clip)
            .fixedSize(horizontal: false, vertical: true)
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func makeBody(configuration: Configuration) -> some View {
        let isCompact = horizontalSizeClass == .compact
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .frame(minWidth: isCompact ? 170 : 0)
            .padding(.horizontal, isCompact ? 18 : 22)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 18 : 16)
                    .fill(Color(red: 0.94, green: 0.79, blue: 0.39))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func makeBody(configuration: Configuration) -> some View {
        let isCompact = horizontalSizeClass == .compact
        configuration.label
            .font(.headline)
            .foregroundStyle(.black.opacity(0.8))
            .frame(minWidth: isCompact ? 170 : 0)
            .padding(.horizontal, isCompact ? 20 : 18)
            .padding(.vertical, isCompact ? 11 : 10)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 18 : 14)
                    .fill(Color.white.opacity(0.82))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    ContentView()
}

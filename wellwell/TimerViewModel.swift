//
//  TimerViewModel.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import Foundation
import Combine

final class TimerViewModel: ObservableObject {
    enum StreakMood {
        case sleepy
        case happy
        case excited
        case golden
    }

    enum SessionState {
        case idle
        case focusRunning
        case waitingForBreakConfirmation
        case breakRunning
        case waitingForWorkConfirmation
        case overdueBreak
        case overdueWork
    }

    @Published var state: SessionState = .idle
    @Published var timeRemaining: Int = 25 * 60
    @Published var showStreakReaction: Bool = false
    @Published var streakDays: Int = 0
    @Published var streakMood: StreakMood = .happy
    @Published private(set) var sessionHistory: [SessionRecord] = []
    
    private var timer: Timer?
    private var overdueTimer: Timer?
    private let overdueInterval: TimeInterval = 120

    @Published var focusMinutes: Int = 25
    @Published var breakMinutes: Int = 5
    @Published var sessionsUntilLongBreak: Int = 4
    @Published var longBreakMinutes: Int = 15
    @Published private(set) var completedFocusSessions: Int = 0
    var isUpcomingBreakLong: Bool = false

    var focusDuration: Int {
        max(1, focusMinutes) * 60
    }

    var breakDuration: Int {
        max(1, breakMinutes) * 60
    }

    var longBreakDuration: Int {
        max(1, longBreakMinutes) * 60
    }

    var upcomingBreakLabel: String {
        isUpcomingBreakLong ? "long break" : "short break"
    }

    var completedSessionProgressText: String {
        "\(completedFocusSessions) / \(safeSessionsUntilLongBreak)"
    }

    private enum DefaultsKeys {
        static let focusMinutes = "focusMinutes"
        static let breakMinutes = "breakMinutes"
        static let sessionsUntilLongBreak = "sessionsUntilLongBreak"
        static let longBreakMinutes = "longBreakMinutes"
        static let sessionHistory = "sessionHistory"
    }

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    private var safeSessionsUntilLongBreak: Int {
        max(1, sessionsUntilLongBreak)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSettings()

        $focusMinutes
            .sink { [weak self] value in
                self?.savePositive(value, forKey: DefaultsKeys.focusMinutes, fallback: 25)
                self?.resetIfIdle()
            }
            .store(in: &cancellables)

        $breakMinutes
            .sink { [weak self] value in
                self?.savePositive(value, forKey: DefaultsKeys.breakMinutes, fallback: 5)
                self?.resetIfIdle()
            }
            .store(in: &cancellables)

        $sessionsUntilLongBreak
            .sink { [weak self] value in
                self?.savePositive(value, forKey: DefaultsKeys.sessionsUntilLongBreak, fallback: 4)
            }
            .store(in: &cancellables)

        $longBreakMinutes
            .sink { [weak self] value in
                self?.savePositive(value, forKey: DefaultsKeys.longBreakMinutes, fallback: 15)
            }
            .store(in: &cancellables)

    }

    private func resetIfIdle() {
        if state == .idle {
            timeRemaining = focusDuration
        }
    }

    func startWork() {
        stopAllSounds()
        clearOverdueState()
        cancelAllFollowUps()
        stopTimer()

        state = .focusRunning
        timeRemaining = focusDuration

        SoundManager.shared.playOneShot(name: "well_start_timer")

        startTimer()
    }

    func startBreak() {
        stopAllSounds()
        clearOverdueState()
        cancelAllFollowUps()
        stopTimer()

        state = .breakRunning
        timeRemaining = isUpcomingBreakLong ? longBreakDuration : breakDuration

        startTimer()
    }

    func resumeWork() {
        stopAllSounds()
        clearOverdueState()
        cancelAllFollowUps()
        stopTimer()

        state = .focusRunning
        timeRemaining = focusDuration

        SoundManager.shared.playOneShot(name: "well_start_timer")

        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard timeRemaining > 0 else {
            handleTimerFinished()
            return
        }

        timeRemaining -= 1
    }

    private func handleTimerFinished() {
        stopTimer()

        switch state {
        case .focusRunning:
            completedFocusSessions += 1
            isUpcomingBreakLong = completedFocusSessions % safeSessionsUntilLongBreak == 0
            state = .waitingForBreakConfirmation
            registerCompletedPomodoro()

            SoundManager.shared.playOneShot(name: "well_focus_done")

            NotificationManager.shared.notifyFocusEnded()
            NotificationManager.shared.cancelBreakFollowUp()
            NotificationManager.shared.scheduleBreakFollowUp(after: overdueInterval)

            scheduleOverdueTimer(after: overdueInterval) { [weak self] in
                guard let self else { return }
                if self.state == .waitingForBreakConfirmation {
                    self.state = .overdueBreak
                    SoundManager.shared.playLoop(name: "well_angry")
                }
            }

        case .breakRunning:
            state = .waitingForWorkConfirmation
            if isUpcomingBreakLong {
                completedFocusSessions = 0
            }
            isUpcomingBreakLong = false

            SoundManager.shared.playOneShot(name: "well_break")

            NotificationManager.shared.notifyBreakEnded()
            NotificationManager.shared.cancelWorkFollowUp()
            NotificationManager.shared.scheduleWorkFollowUp(after: overdueInterval)

            scheduleOverdueTimer(after: overdueInterval) { [weak self] in
                guard let self else { return }
                if self.state == .waitingForWorkConfirmation {
                    self.state = .overdueWork
                    SoundManager.shared.playLoop(name: "well_back_to_work")
                }
            }

        default:
            break
        }
    }

    private func scheduleOverdueTimer(after seconds: TimeInterval, action: @escaping () -> Void) {
        clearOverdueState()
        overdueTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            DispatchQueue.main.async {
                action()
            }
        }
    }

    private func clearOverdueState() {
        overdueTimer?.invalidate()
        overdueTimer = nil
    }

    private func cancelAllFollowUps() {
        NotificationManager.shared.cancelBreakFollowUp()
        NotificationManager.shared.cancelWorkFollowUp()
    }

    private func stopAllSounds() {
        SoundManager.shared.stop()
    }

    func triggerOpeningReaction() {
        guard !showStreakReaction else { return }
        streakDays = calculateStreakDays(from: sessionHistory)
        streakMood = mood(for: streakDays)
        showStreakReaction = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.showStreakReaction = false
        }
    }

    func formattedTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func resetTimer() {
        stopAllSounds()
        overdueTimer?.invalidate()
        stopTimer()
        isUpcomingBreakLong = false
        completedFocusSessions = 0
        state = .idle
        timeRemaining = focusDuration
    }

    private func loadSettings() {
        focusMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.focusMinutes), fallback: 25, range: 1...120)
        breakMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.breakMinutes), fallback: 5, range: 1...60)
        sessionsUntilLongBreak = sanitized(defaults.integer(forKey: DefaultsKeys.sessionsUntilLongBreak), fallback: 4, range: 1...12)
        longBreakMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.longBreakMinutes), fallback: 15, range: 1...90)
        sessionHistory = loadSessionHistory()
        timeRemaining = focusDuration
    }

    var totalCompletedSessions: Int {
        sessionHistory.count
    }

    var totalFocusMinutesAllTime: Int {
        sessionHistory.reduce(0) { $0 + ($1.focusSeconds / 60) }
    }

    var todayFocusMinutes: Int {
        let calendar = Calendar.current
        return sessionHistory
            .filter { calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + ($1.focusSeconds / 60) }
    }

    var weeklyFocusSummary: [(dayLabel: String, minutes: Int)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let minutes = sessionHistory
                .filter { $0.completedAt >= dayStart && $0.completedAt < nextDay }
                .reduce(0) { $0 + ($1.focusSeconds / 60) }
            let dayLabel = date.formatted(.dateTime.weekday(.abbreviated))
            return (dayLabel, minutes)
        }
    }

    private func sanitized(_ value: Int, fallback: Int, range: ClosedRange<Int>) -> Int {
        guard value > 0 else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    private func savePositive(_ value: Int, forKey key: String, fallback: Int) {
        let sanitizedValue: Int
        switch key {
        case DefaultsKeys.focusMinutes:
            sanitizedValue = sanitized(value, fallback: fallback, range: 1...120)
        case DefaultsKeys.breakMinutes:
            sanitizedValue = sanitized(value, fallback: fallback, range: 1...60)
        case DefaultsKeys.sessionsUntilLongBreak:
            sanitizedValue = sanitized(value, fallback: fallback, range: 1...12)
        case DefaultsKeys.longBreakMinutes:
            sanitizedValue = sanitized(value, fallback: fallback, range: 1...90)
        default:
            sanitizedValue = fallback
        }
        if value != sanitizedValue {
            switch key {
            case DefaultsKeys.focusMinutes:
                focusMinutes = sanitizedValue
            case DefaultsKeys.breakMinutes:
                breakMinutes = sanitizedValue
            case DefaultsKeys.sessionsUntilLongBreak:
                sessionsUntilLongBreak = sanitizedValue
            case DefaultsKeys.longBreakMinutes:
                longBreakMinutes = sanitizedValue
            default:
                break
            }
        }
        defaults.set(sanitizedValue, forKey: key)
    }

    private func registerCompletedPomodoro() {
        let record = SessionRecord(focusSeconds: focusDuration)
        sessionHistory.append(record)
        trimHistory()
        saveSessionHistory()
        streakDays = calculateStreakDays(from: sessionHistory)
        streakMood = mood(for: streakDays)
    }

    private func trimHistory() {
        guard sessionHistory.count > 730 else { return }
        sessionHistory = Array(sessionHistory.suffix(730))
    }

    private func loadSessionHistory() -> [SessionRecord] {
        guard let raw = defaults.data(forKey: DefaultsKeys.sessionHistory) else {
            return []
        }
        return (try? JSONDecoder().decode([SessionRecord].self, from: raw)) ?? []
    }

    private func saveSessionHistory() {
        guard let data = try? JSONEncoder().encode(sessionHistory) else { return }
        defaults.set(data, forKey: DefaultsKeys.sessionHistory)
    }

    private func calculateStreakDays(from history: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(history.map { calendar.startOfDay(for: $0.completedAt) })
        guard !uniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let includesToday = uniqueDays.contains(today)
        var cursor = includesToday ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        guard uniqueDays.contains(cursor) else { return 0 }

        var streak = 0
        while uniqueDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private func mood(for streakDays: Int) -> StreakMood {
        switch streakDays {
        case 0...1:
            return .sleepy
        case 2...4:
            return .happy
        case 5...9:
            return .excited
        default:
            return .golden
        }
    }
}

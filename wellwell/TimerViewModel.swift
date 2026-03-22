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
    @Published var sessionLabel: String = ""
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
        static let sessionLabel = "sessionLabel"
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

        $sessionLabel
            .sink { [weak self] value in
                self?.defaults.set(value.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKeys.sessionLabel)
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

    var totalSessionsCompleted: Int {
        sessionHistory.count
    }

    var totalFocusMinutes: Int {
        sessionHistory.reduce(0) { $0 + $1.focusMinutes }
    }

    var todayFocusMinutes: Int {
        let calendar = Calendar.current
        return sessionHistory
            .filter { calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + $1.focusMinutes }
    }

    var currentStreakDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.completedAt) })
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var currentDay = calendar.startOfDay(for: .now)

        while uniqueDays.contains(currentDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }
            currentDay = previousDay
        }

        return streak
    }

    func weeklyFocusMinutes() -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)

        return (0..<7).map { offset in
            guard
                let dayStart = calendar.date(byAdding: .day, value: offset, to: weekStart),
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)
            else {
                return 0
            }

            return sessionHistory
                .filter { $0.completedAt >= dayStart && $0.completedAt < dayEnd }
                .reduce(0) { $0 + $1.focusMinutes }
        }
    }

    func triggerOpeningReaction() {
        guard !showStreakReaction else { return }
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
        sessionLabel = defaults.string(forKey: DefaultsKeys.sessionLabel) ?? ""
        loadHistory()
        timeRemaining = focusDuration
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
        let trimmedLabel = sessionLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = SessionRecord(
            focusMinutes: focusMinutes,
            sessionLabel: trimmedLabel,
            wasLongBreakSession: isUpcomingBreakLong
        )
        sessionHistory.insert(record, at: 0)
        if sessionHistory.count > 120 {
            sessionHistory = Array(sessionHistory.prefix(120))
        }
        saveHistory()
    }

    private func loadHistory() {
        guard let data = defaults.data(forKey: DefaultsKeys.sessionHistory) else {
            sessionHistory = []
            return
        }
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([SessionRecord].self, from: data) {
            sessionHistory = decoded.sorted { $0.completedAt > $1.completedAt }
        } else {
            sessionHistory = []
        }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(sessionHistory) {
            defaults.set(data, forKey: DefaultsKeys.sessionHistory)
        }
    }
}

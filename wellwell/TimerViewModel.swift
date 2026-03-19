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
    
    private var timer: Timer?
    private var overdueTimer: Timer?
    private let overdueInterval: TimeInterval = 120
    
    @Published var focusMinutes: Int = 25
    @Published var breakMinutes: Int = 5
    @Published private(set) var streakDays: Int = 0
    @Published var showStreakReaction: Bool = false

    private let calendar = Calendar.current
    private let dailyPomodoroGoal = 4
    private let streakDaysKey = "streakDays"
    private let lastQualifiedDayKey = "lastQualifiedDay"
    private let todaysPomodoroCountKey = "todaysPomodoroCount"
    private let todaysPomodoroDateKey = "todaysPomodoroDate"
    private let userDefaults = UserDefaults.standard

    var focusDuration: Int {
        max(1, focusMinutes) * 60
    }

    var breakDuration: Int {
        max(1, breakMinutes) * 60
    }
    private var cancellables = Set<AnyCancellable>()

    init() {
        $focusMinutes
            .sink { [weak self] _ in
                self?.resetIfIdle()
            }
            .store(in: &cancellables)

        $breakMinutes
            .sink { [weak self] _ in
                self?.resetIfIdle()
            }
            .store(in: &cancellables)

        loadStreakState()
    }

    var streakMood: StreakMood {
        switch streakDays {
        case ..<1:
            return .sleepy
        case 1...3:
            return .happy
        case 4...7:
            return .excited
        default:
            return .golden
        }
    }

    func triggerOpeningReaction() {
        showStreakReaction = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.showStreakReaction = false
        }
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
        timeRemaining = breakDuration
        
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
    
    func formattedTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func loadStreakState() {
        streakDays = userDefaults.integer(forKey: streakDaysKey)
        rollOverIfNeeded()
    }

    private func rollOverIfNeeded(now: Date = Date()) {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)

        if let lastQualifiedDay = userDefaults.object(forKey: lastQualifiedDayKey) as? Date {
            let normalizedQualifiedDay = calendar.startOfDay(for: lastQualifiedDay)
            if normalizedQualifiedDay < (yesterday ?? today) {
                streakDays = 0
                userDefaults.set(0, forKey: streakDaysKey)
            }
        } else {
            streakDays = 0
            userDefaults.set(0, forKey: streakDaysKey)
        }

        if let trackedDay = userDefaults.object(forKey: todaysPomodoroDateKey) as? Date {
            let normalizedTrackedDay = calendar.startOfDay(for: trackedDay)
            if normalizedTrackedDay != today {
                userDefaults.set(0, forKey: todaysPomodoroCountKey)
                userDefaults.set(today, forKey: todaysPomodoroDateKey)
            }
        } else {
            userDefaults.set(today, forKey: todaysPomodoroDateKey)
            userDefaults.set(0, forKey: todaysPomodoroCountKey)
        }
    }

    private func registerCompletedPomodoro(now: Date = Date()) {
        rollOverIfNeeded(now: now)

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)

        var todaysCount = userDefaults.integer(forKey: todaysPomodoroCountKey)
        todaysCount += 1
        userDefaults.set(todaysCount, forKey: todaysPomodoroCountKey)
        userDefaults.set(today, forKey: todaysPomodoroDateKey)

        guard todaysCount >= dailyPomodoroGoal else {
            return
        }

        if let lastQualifiedDay = userDefaults.object(forKey: lastQualifiedDayKey) as? Date {
            let normalizedQualifiedDay = calendar.startOfDay(for: lastQualifiedDay)

            if normalizedQualifiedDay == today {
                return
            } else if normalizedQualifiedDay == yesterday {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        userDefaults.set(streakDays, forKey: streakDaysKey)
        userDefaults.set(today, forKey: lastQualifiedDayKey)
    }
}

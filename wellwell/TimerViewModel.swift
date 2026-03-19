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
    @Published var sessionsUntilLongBreak: Int = 4
    @Published var longBreakMinutes: Int = 15
    @Published private(set) var completedFocusSessions: Int = 0

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
        "\(completedFocusSessions) / \(sessionsUntilLongBreak)"
    }

    private enum DefaultsKeys {
        static let focusMinutes = "focusMinutes"
        static let breakMinutes = "breakMinutes"
        static let sessionsUntilLongBreak = "sessionsUntilLongBreak"
        static let longBreakMinutes = "longBreakMinutes"
    }

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

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
            isUpcomingBreakLong = completedFocusSessions % sessionsUntilLongBreak == 0
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
        focusMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.focusMinutes), fallback: 25)
        breakMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.breakMinutes), fallback: 5)
        sessionsUntilLongBreak = sanitized(defaults.integer(forKey: DefaultsKeys.sessionsUntilLongBreak), fallback: 4)
        longBreakMinutes = sanitized(defaults.integer(forKey: DefaultsKeys.longBreakMinutes), fallback: 15)
        timeRemaining = focusDuration
    }

    private func sanitized(_ value: Int, fallback: Int) -> Int {
        value > 0 ? value : fallback
    }

    private func savePositive(_ value: Int, forKey key: String, fallback: Int) {
        let sanitizedValue = sanitized(value, fallback: fallback)
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
}

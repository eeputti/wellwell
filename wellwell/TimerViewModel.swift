//
//  TimerViewModel.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import Foundation
import Combine

final class TimerViewModel: ObservableObject {
    
    enum SessionState {
        case idle
        case focusRunning
        case waitingForBreakConfirmation
        case breakRunning
        case waitingForWorkConfirmation
    }
    
    @Published var state: SessionState = .idle
    @Published var timeRemaining: Int = 25 * 60
    
    private var timer: Timer?
    
    let focusDuration = 25 * 60
    let breakDuration = 5 * 60
    
    func startWork() {
        stopTimer()
        state = .focusRunning
        timeRemaining = focusDuration
        startTimer()
    }
    
    func startBreak() {
        stopTimer()
        state = .breakRunning
        timeRemaining = breakDuration
        startTimer()
    }
    
    func resumeWork() {
        startWork()
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
            NotificationManager.shared.send(
                title: "time for a break",
                body: "stand up, move a little, drink water"
            )

        case .breakRunning:
            state = .waitingForWorkConfirmation
            NotificationManager.shared.send(
                title: "ready to continue?",
                body: "your break can end now"
            )

        default:
            break
        }
    }
    
    func formattedTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

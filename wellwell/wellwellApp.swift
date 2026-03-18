//
//  wellwellApp.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import SwiftUI

@main
struct wellwellApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

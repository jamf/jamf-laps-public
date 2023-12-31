//
//  Jamf_LAPSApp.swift
//  Jamf LAPS
//
//  Copyright 2023, Jamf

import SwiftUI

@main
struct Jamf_LAPSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 330, maxHeight: 330)

        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 175, maxHeight: 175)
        }
        
    }
}

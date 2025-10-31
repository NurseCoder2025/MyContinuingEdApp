//
//  Settings.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/29/25.
//

// Purpose: To hold properties that serve as settings for the app and used for controlling user
// preferences for various features.

import Foundation
import Combine

// MARK: - APP SETTINGS STRUCT
struct AppSettings: Codable {
    var daysUntilPrimaryNotification: Int = 30
    var daysUntilSecondaryNotification: Int = 7
    
    var showExpiringCesNotification: Bool = true
    var showRenewalEndingNotification: Bool = true
    var showRenewalLateFeeNotification: Bool = true
    var showDAINotifications: Bool = true
    
    
}//: AppSettings


// MARK: - CE APP SETTINGS CLASS
final class CeAppSettings: ObservableObject {
    // MARK: - PROPERTIES
    @Published var settings: AppSettings
    private let settingsFileURL: URL
    private var cancellable: AnyCancellable?
    
    // MARK: - FUNCTIONS
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: settingsFileURL)
        }
    }//: saveSettings()
    
    static func loadSettings(from url: URL) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }//: loadSettings(URL)
        
    
    // MARK: - INIT
    init() {
        let settingsFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        settingsFileURL = settingsFile.appendingPathComponent("settings.json")
        settings = Self.loadSettings(from: settingsFileURL) ?? AppSettings()
        // Implementing the sink to call the saveSettings function automatically whenever the
        // published property settings changes
        cancellable = $settings.sink { [weak self] _ in
            self?.saveSettings()
        }
    }//: INIT
    
}//: CE APP SETTINGS

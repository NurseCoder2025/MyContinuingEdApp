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
    var basicUnlockPurchased: Bool = false
    var proSubscriptionPurchased: Bool = false
    
    var appPurchaseStatus: PurchaseStatus = .free
    var subscriptionStatus: SubscriptionStatus = .inactive
    
    
    var daysUntilPrimaryNotification: Int = 30
    var daysUntilSecondaryNotification: Int = 7
    
    var showExpiringCesNotification: Bool = true
    var showRenewalEndingNotification: Bool = true
    var showRenewalLateFeeNotification: Bool = true
    var showDAINotifications: Bool = false
    
    
}//: AppSettings


// MARK: - CE APP SETTINGS CLASS
final class CeAppSettings: ObservableObject {
    // MARK: - PROPERTIES
    @Published var settings: AppSettings = AppSettings()
    private(set) var settingsFileURL: URL? = nil
    private var cancellable: AnyCancellable? = nil
    private var localSettingsURL: URL? = nil
    private var iCloudSettingsURL: URL? = nil
    
    // File Monitor properties for updating the settings property whenever
    // settings.json is changed elsewhere in the app
    private var fileMonitorSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    
    // MARK: - FUNCTIONS
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            if let settingsLocation = settingsFileURL {
                try? data.write(to: settingsLocation)
            }
            // Also save to both locations if possible
            if let localURL = localSettingsURL {
                try? data.write(to: localURL)
            }
            if let icloudURL = iCloudSettingsURL {
                try? data.write(to: icloudURL)
            }
        }
    }//: saveSettings()
    
    static func loadSettings(from url: URL) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }//: loadSettings(URL)
    
    private static func modificationDate(for url: URL) -> Date? {
        return (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }
    
    // MARK: - FILE MONITORING
    /// This method updates the settings property whenever the settings.json file is updated by another part of the app.
    /// Called by the file monitor
    private func reloadSettingsFromDisk() {
        guard let url = settingsFileURL, let newSettings = CeAppSettings.loadSettings(from: url) else { return }
        settings = newSettings
    }
    
    private func startSettingsFileMonitoring() {
        guard let url = settingsFileURL else { return }
        stopMonitoringSettingsFile()
        
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        fileMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: DispatchQueue.global())
        fileMonitorSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.reloadSettingsFromDisk()
            }
        }
        
        fileMonitorSource?.setCancelHandler { [weak self] in
            if let descriptor = self?.fileDescriptor, descriptor != -1 {
                close(descriptor)
            }
            self?.fileDescriptor = -1
            self?.fileMonitorSource = nil
        }
        
        fileMonitorSource?.resume()
        
    }//: startFileMonitoringSettings()
    
    
    private func stopMonitoringSettingsFile() {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    } //: stopMonitoringSettingsFile
    
    
    // MARK: - INIT & DEINIT
    init() {
        // Initialize all properties synchronously
        let localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CE Cache")
        let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("CE Cache")
        let localSettings = localURL.appendingPathComponent("settings.json")
        let icloudSettings = iCloudURL?.appendingPathComponent("settings.json")
        self.localSettingsURL = localSettings
        self.iCloudSettingsURL = icloudSettings
        
        // Default to local until async resolves
        self.settingsFileURL = localSettings
        
        // Ensure local directory exists
        try? FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
        if let icloudDir = iCloudURL {
            try? FileManager.default.createDirectory(at: icloudDir, withIntermediateDirectories: true)
        }
        // Load settings asynchronously and resolve conflicts
        DispatchQueue.global(qos: .background).async { [weak self] in
            var loadedSettings: AppSettings = AppSettings()
            var chosenURL: URL = localSettings
            let localDate = Self.modificationDate(for: localSettings)
            let icloudDate = icloudSettings != nil ? Self.modificationDate(for: icloudSettings!) : nil
            let localExists = FileManager.default.fileExists(atPath: localSettings.path)
            let icloudExists = icloudSettings != nil ? FileManager.default.fileExists(atPath: icloudSettings!.path) : false
            if localExists && icloudExists {
                // Both exist, compare dates
                if let lDate = localDate, let iDate = icloudDate {
                    if iDate > lDate {
                        loadedSettings = Self.loadSettings(from: icloudSettings!) ?? AppSettings()
                        chosenURL = icloudSettings!
                    } else {
                        loadedSettings = Self.loadSettings(from: localSettings) ?? AppSettings()
                        chosenURL = localSettings
                    }
                } else if icloudDate != nil {
                    loadedSettings = Self.loadSettings(from: icloudSettings!) ?? AppSettings()
                    chosenURL = icloudSettings!
                } else {
                    loadedSettings = Self.loadSettings(from: localSettings) ?? AppSettings()
                    chosenURL = localSettings
                }
            } else if icloudExists {
                loadedSettings = Self.loadSettings(from: icloudSettings!) ?? AppSettings()
                chosenURL = icloudSettings!
            } else if localExists {
                loadedSettings = Self.loadSettings(from: localSettings) ?? AppSettings()
                chosenURL = localSettings
            } else {
                loadedSettings = AppSettings()
                chosenURL = localSettings
            }
            // After resolving, save to both locations to sync
            if let data = try? JSONEncoder().encode(loadedSettings) {
                try? data.write(to: localSettings)
                if let icloudSettings = icloudSettings {
                    try? data.write(to: icloudSettings)
                }
            }
            DispatchQueue.main.async {
                self?.settingsFileURL = chosenURL
                self?.settings = loadedSettings
                self?.cancellable = self?.$settings.sink { [weak self] _ in
                    self?.saveSettings()
                }
                self?.startSettingsFileMonitoring()
            }
        }
    }//: INIT
    
    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.stopMonitoringSettingsFile()
        }
    }//: DEINIT
    
}//: CE APP SETTINGS

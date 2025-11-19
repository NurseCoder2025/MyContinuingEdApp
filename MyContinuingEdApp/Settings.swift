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
    var appPurchaseStatus: PurchaseStatus = .free
    var proSubscriptionStatus: SubscriptionStatus = .freeTrial
    var freeTrialEndDate: Date? = nil
    var proSubscrptionEndDate: Date? = nil
    var purchaseHistory: [Date: PurchaseStatus] = [:]
    
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
    @Published var settings: AppSettings = AppSettings()
    private(set) var settingsFileURL: URL? = nil
    private var cancellable: AnyCancellable? = nil
    
    // MARK: - FUNCTIONS
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings), let settingsLocation = settingsFileURL {
            try? data.write(to: settingsLocation)
        }
    }//: saveSettings()
    
    static func loadSettings(from url: URL) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }//: loadSettings(URL)
        
    
    // MARK: - INIT
    init() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent("Documents")
                .appendingPathComponent("CE Cache")
            let fileURL = (iCloudURL ?? localURL).appendingPathComponent("settings.json")
            if let icloudDir = iCloudURL {
                try? FileManager.default.createDirectory(at: icloudDir, withIntermediateDirectories: true)
            }//: IF LET
           
            let loadedSettings = Self.loadSettings(from: fileURL) ?? AppSettings()
            DispatchQueue.main.async {
                self?.settingsFileURL = fileURL
                self?.settings = loadedSettings
                // Implementing the sink to call the saveSettings function
                // automatically whenever the published property settings changes
                self?.cancellable = self?.$settings.sink { [weak self] _ in
                    self?.saveSettings()
                }
            }//: DisptachQueue
        }//: DispatchQueue (global)
    }//: INIT
    
}//: CE APP SETTINGS

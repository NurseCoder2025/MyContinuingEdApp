//
//  DataController-Settings.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/18/25.
//

import Foundation


extension DataController {
    
    /// This method reads out the contents of the AppSettings struct which are encoded in a document within FileManager locally.  This was originally
    /// created by the CeAppSettings class initializer, but reusing some of the functionality so that other functions within DataController can
    /// easily access all user settings as needed.
    /// - Returns: AppSettings struct decoded from the settings.json file which contains all saved user settings for the app
    func accessUserSettings() -> AppSettings? {
        let settingsFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CE Cache")
            .appendingPathComponent("settings.json")
        
        guard let data = try? Data(contentsOf: settingsFileURL) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }//: accessUserSettings()
    
    
    /// Method for writing changes to the shared AppSettings struct and saving the changed struct to both
    /// the local and iCloud locations.
    /// - Parameter settings: AppSettings struct (passed in from the accessUserSettings method)
    ///
    /// Due to the file monitor methods placed within the CeAppSettings class, any changes made to the settings.json file
    /// outside of the class will be automatically written to the class's settings property so that changes are reflected in the
    /// UI.
    func modifyUserSettings(_ settings: AppSettings) {
        let localSettingsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CE Cache")
            .appendingPathComponent("settings.json")
        
        let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("CE Cache")
            .appendingPathComponent("settings.json")
        
        
       // Writing updated settings struct to both local and iCloud versions
        if let localData = try? JSONEncoder().encode(settings) {
            try? localData.write(to: localSettingsURL)
        }
        
        if let cloudSettings = iCloudURL, let cloudData = try? JSONEncoder().encode(settings) {
            try? cloudData.write(to: cloudSettings)
        }
        
    }//: ModifyUserSettings
    
    
}//: DATACONTROLLER

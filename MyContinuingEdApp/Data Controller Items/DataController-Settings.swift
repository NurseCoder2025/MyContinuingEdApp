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
    
    
}//: DATACONTROLLER

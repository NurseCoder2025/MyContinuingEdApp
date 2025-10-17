//
//  Settings-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation


extension Settings {
    var settingsUserProfession: String {
        get {userProfession ?? ""}
        set {userProfession = newValue}
    }
    
}

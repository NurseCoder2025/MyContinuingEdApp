//
//  Settings.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/29/25.
//

// Purpose: To hold properties that serve as settings for the app and used for controlling user
// preferences for various features.

import Foundation


// MARK: - APP SETTINGS STRUCT
struct AppSettings: Codable {
    var appPurchaseStatus: PurchaseStatus = .free
    
    
    var daysUntilPrimaryNotification: Int = 30
    var daysUntilSecondaryNotification: Int = 7
    
    var showExpiringCesNotification: Bool = true
    var showRenewalEndingNotification: Bool = true
    var showRenewalLateFeeNotification: Bool = true
    var showDAINotifications: Bool = false
    
    
}//: AppSettings




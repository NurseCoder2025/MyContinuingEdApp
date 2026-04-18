//
//  UserSettingsRelatedEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import Foundation


// MARK: - SETTINGS

/// Enum used for setting the value of Setting keys pertaining to the numerical value shown
/// in badges, such as the one for each Tag and RenewalPeriod in SidebarView.
///
/// - Important: Be sure to use the raw value when setting the value for each setting key, but
/// can use the regular enum in pickers or other UI controls.
///
/// - Note: This enum has a computed property called labelText which returns a String value
/// which can be used in any UI control such as Pickers when needed. The values are as follows:
/// .allItems = "All Assigned CEs", .activeItems = "CEs to Complete", & .completedItems =
/// "Completed CEs".
enum BadgeCountOption: String, CaseIterable, Identifiable, Hashable {
    case allItems = "allItems"
    case activeItems = "activeItems"
    case completedItems = "completedItems"
    
    var id: String { self.rawValue }
    
    var labelText: String {
        switch self {
        case .allItems:
            return "All Assigned CEs"
        case .activeItems:
            return "CEs To Complete"
        case .completedItems:
            return "Completed CEs"
        }//: SWITCH
    }//: labelText
}//: BadgeCountOption

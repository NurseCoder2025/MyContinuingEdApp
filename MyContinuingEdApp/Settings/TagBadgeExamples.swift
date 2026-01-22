//
//  TagBadgeExamples.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/22/26.
//

import Foundation
import SwiftUI

// MARK: - BadgeExample STRUCT

/// Custom data type conforming to Identifiable and Hashable that is used to create custom text for users that explains
/// in greater detail what each Tag Activity Indicator value means.
///
/// ID property is automatically assigned as a UUID at initialization.  There are two mutating functions inside this struct that
/// set the badge value and explanatory text, depending on what BadgeCountOption enum value was passed in as an
/// argument.
///
/// Default values for the number of CE activities assigned to a tag are as follows:
/// - Total CE activites: 10 [use sampleTotal]
/// - CEs that can still be completed: 5 (out of the 10 total) [use sampleActive]
/// - CEs that have been completed: 3 (out of the 10 total) [use sampleCompleted]
struct BadgeExample: Identifiable, Hashable {
    // MARK: - PROPERTIES
    let id: UUID = UUID()
    let badgeCase: BadgeCountOption
    let sampleTotal: Int = 10
    let sampleActive: Int = 5
    let sampleCompleted: Int = 3
    
    var badgeNumber: Int = 0
    var explaination: String = ""
    
    // MARK: - METHODS
    mutating func setBadgeValue() {
        switch badgeCase {
        case .allItems:
            badgeNumber = sampleTotal
        case .activeItems:
            badgeNumber = sampleActive
        case .completedItems:
            badgeNumber = sampleCompleted
        }
    }//: setBadgeValue()
    
    mutating func setBadgeExplaination() {
        switch badgeCase {
        case .allItems:
            explaination = "Example:\nTotal CEs assigned to tag: \(sampleTotal)\n-----------\nCustom Tag \(sampleTotal)"
        case .activeItems:
            explaination = "Example:\nTotal CEs assigned to tag: \(sampleTotal)\nCEs that can still be completed: \(sampleActive)\n-------------\nCustom Tag \(sampleActive)"
        case .completedItems:
            explaination = "Example:\nTotal CEs assigned to tag: \(sampleTotal)\nCompleted CEs: \(sampleCompleted)\n--------------\nCustom Tag \(sampleCompleted)"
        }//: SWITCH
    }//: setBadgeExplaination
    
    // MARK: - INIT
    init(
        badgeCase: BadgeCountOption,
    ) {
        self.badgeCase = badgeCase
        
        setBadgeValue()
        setBadgeExplaination()
    }//: INIT
}//: STRUCT

// MARK: - BADGE EXAMPLE DATA

/// Global constant which contains 3 BadgeExample objects that make it easier to display custom text to the user
/// whenever the Tag Activity Count picker control is changed by the user in Setitings. See GeneralUISettingsView
/// for where these values are used.
let allTagBadgeExamples: [BadgeExample] = [
    BadgeExample(badgeCase: .allItems),
    BadgeExample(badgeCase: .activeItems),
    BadgeExample(badgeCase: .completedItems)
]//: allTagBadgeExamples

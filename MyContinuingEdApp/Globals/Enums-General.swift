//
//  Enums-General.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

import Foundation


// MARK: - Sort TYPE
/// This enum is used in ContentView for the Sorting menu as a way to easily tag sort values.  Each enum type has a raw String
/// value that corresponds to a CeActivity property that the user can sort on.
enum SortType: String {
    case name = "activityTitle"
    case dateCreated = "activityAddedDate"
    case dateModified = "modifiedDate"
    case dateCompleted = "dateCompleted"
    case activityCost = "cost"
    case awardedCEAmount = "ceAwarded"
    case typeOfCE = "ceType"
    case format = "formatType"
}


// MARK: - Enum for sheet types
enum SheetType {
    case renewal, issuer, specialCat
}


// MARK: - Enum for credential types
/// Enum for handling the different types of credentials that can be added to the app.  Within this enum are several computed properties
/// to allow for easy access to display names (singular and plural) and SF Symbols icons for each type.  The string values within this enum
/// will be used to populate the credentialType property in the Credential entity object.
enum CredentialType: String, CaseIterable {
    case all
    // Added a placeholder value, "", to the enum in order to allow for an empty selection
    // in a picker control.
    case placeholder = ""
    case license
    case certification
    case endorsement
    case membership
    case other
    
    // Computed property for pickers and other controls where the all case is not needed
    static var pickerChoices: [CredentialType] {
        CredentialType.allCases.filter {$0 != .all}
    }
    
    // Computed property for displaying only those types that users can add credentials to
    //  i.e. not the placeholder
    static var addableTypes: [CredentialType] {
        // Will create an array for all, license, certification, endorsement, membership, other
        CredentialType.allCases.filter {$0 != .placeholder}
    }
        
    
    var displaySingularName: String {
        switch self {
        case .all:
            return "All"
        case .placeholder:
            return "Select Type"
        case .license:
            return "License"
        case .certification:
            return "Certification"
        case .endorsement:
            return "Endorsement"
        case .membership:
            return "Membership"
        case .other:
            return "Other"
        }
    }//: DISPLAY NAME (singular)
    
    var displayPluralName: String {
        switch self {
        case .all:
            return "All"
        case .placeholder:
            return ""
        case .license:
            return "Licenses"
        case .certification:
            return "Certifications"
        case .endorsement:
            return "Endorsements"
        case .membership:
            return "Memberships"
        case .other:
            return "Others"
        
        }
    }//: DISPLAY PLURAL NAME
    
    var typeIcon: String {
        switch self {
        case .all:
            return "folder.fill"
        case .placeholder:
            return "questionmark.app.fill"
        case .license:
            return "person.text.rectangle.fill"
        case .certification:
            return "checkmark.seal.fill"
        case .endorsement:
            return "rectangle.fill.badge.plus"
        case .membership:
            return "person.2.fill"
        case .other:
            return "questionmark.circle.fill"
        }
        
    }//: TYPE ICONS
    
    static var pluralLabels: [String] {
        CredentialType.allCases.map { $0.displayPluralName }
    }
    
    static var singleValues: [String] {
        CredentialType.allCases.map { $0.displaySingularName }
    }
}
    

// MARK: - Notification Type ENUM
/// Enum used primarily for creating suffix values that will be appended to the string UUID values of Core Data
/// entities as part of their unique NotificationCenter identifier value. This will allow for multiple notifications for the same
/// object to be created.
enum NotificationType: String, CaseIterable {
    case upcomingExpiration
    case renewalEnding
    case lateFeeStarting
    case disciplineEnding
    case serviceDeadlineApproaching
    case fineDeadlineApproaching
    case ceHoursDeadlineApproaching
}


// MARK: - Calendar Related
enum Month: Int, CaseIterable {
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
    
    var monthName: String {
        switch self {
            case .january: return "January"
            case .february: return "February"
            case .march: return "March"
            case .april: return "April"
            case .may: return "May"
            case .june: return "June"
            case .july: return "July"
            case .august: return "August"
            case .september: return "September"
            case .october: return "October"
            case .november: return "November"
            case .december: return "December"
        }//: SWITCH
    }//: MONTH NAME
    
    var abbreviatedMonthName: String {
        switch self {
            case .january: return "Jan"
            case .february: return "Feb"
            case .march: return "Mar"
            case .april: return "Apr"
            case .may: return "May"
            case .june: return "Jun"
            case .july: return "Jul"
            case .august: return "Aug"
            case .september: return "Sept"
            case .october: return "Oct"
            case .november: return "Nov"
            case .december: return "Dec"
        }
    }//: abbreviatedMonthName
}

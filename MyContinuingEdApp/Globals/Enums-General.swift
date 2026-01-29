//
//  Enums-General.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

import Foundation


// MARK: - Sort TYPE

/// This enum is used in ContentView for the Sorting menu as a way to easily tag sort values.
/// Each enum type has a raw String
/// value that corresponds to a CeActivity property that the user can sort on.
///
/// - Important: The string value associated with each case MUST exactly match the
/// CoreData entity property to be sorted. Otherwise, a fatalError will occur.  Also, whenever
/// adding a new type or removing one, be sure to update the corresponding arrays in
/// ContentViewToolbarView as they organize all sort enum types into categories, and those are
/// used for controlling whether a picker control is enabled or not.
///
/// Case values include:
///     - name: activityTitle
///     - dateCreated: activityAddedDate
///     - dateModified: modifiedDate
///     - dateCompleted: dateCompleted
///     - activityCost: cost
///     - awardedCEAmount: ceAwarded
///     - typeOfCE: ceType
///     - format: formatType
///     - startTime: startTime
enum SortType: String {
    case name = "activityTitle"
    case dateCreated = "activityAddedDate"
    case dateModified = "modifiedDate"
    case dateCompleted = "dateCompleted"
    case activityCost = "cost"
    case awardedCEAmount = "ceAwarded"
    case typeOfCE = "ceType"
    case format = "formatType"
    case startTime = "startTime"
    case endTime = "endTime"
}//: SORT TYPE

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
    

// MARK: - Notification ENUMs

/// Enum used primarily for creating suffix values that will be appended to the string UUID values of Core Data
/// entities as part of their unique NotificationCenter identifier value. This will allow for multiple notifications for the same
/// object to be created.
enum NotificationType: String, CaseIterable {
    case upcomingExpiration
    case renewalProcessStarting
    case renewalEnding
    case sixMonthAlert
    case lateFeeStarting
    case lateFeeBeginsToday
    case disciplineEnding
    case serviceDeadlineApproaching
    case fineDeadlineApproaching
    case ceHoursDeadlineApproaching
    case liveActivityStarting
    case reinstatementDeadline
    case interview
    case additionalTestDate
    case registrationDeadline
    case registrationNeeded
    case achievementEarned
}//: NotificationType

/// Enum used to identify whether the argument being passed into the DataController's createObjectNotifications objType
/// parameter represents a live or non-live event.  This will determine the total number of notifications scheduled.
///
/// Depending on the settings for live event alert notifications, up to 4 total notifications will be scheduled versus just
/// two for non-live notifications. Most objects for which notifications are created are considered to be non-live, such
/// as renewal period related deadlines, disciplinary action related alerts, and expiring CEs.  CeActivities which are
/// a live activity (ex. conference, simulation, webinar, etc.) are considered to be live so additional alerts will be made
/// for them unless the user explicitly indicates they don't want them via settings.
enum ObjectCategory {
    case live, nonLive
}//: NOTIFICATION TARGET

/// Enum used to configure notifications for display at a specified time of day within the DataController's createObjectNotifications
/// method.
///
/// These values correlate with the static properties in the Double extension where the number of seconds from midnight until
/// a given time (10am, 3pm, and 7pm) are calculated.  The createObjectNotifications method will read the enum value argument
/// and then pass in the corresponding Date static property for configuring the time a notification should be shown.
enum TimePreference {
    case morning, afternoon, evening
}//: TimePreference


// MARK: - In App Purchases

/// Enum for indicating whether the user has made an in-app purchase, and if so, which one, or
/// is using the free version of the app.
///
/// This enum has a computed id property that returns a String value for use as a value in the
/// sharedSettings key "purchaseStatus".  Those values are as follows:
///  - .free: "free"
///  - .basicUnlock: "basicUnlock"
///  - .proSubscription: "proSubscription"
///
///  - Note: Protocol conformance for this enum includes Codable & Identifiable.
enum PurchaseStatus: Codable, Identifiable {
    case free, basicUnlock, proSubscription
    
    // Identifiable conformance
    // Needed so that this enum can be used for presenting sheets
    // as an item
    var id: String {
        switch self {
        case .free: return "free"
        case .basicUnlock: return "basicUnlock"
        case .proSubscription: return "proSubscription"
        }
    }//: id
}//: PURHCASE STATUS

/// Enum for indicating that the user has exceeded a pre-determined limit of objects while the
/// app is in free mode. This is an error type that is thrown by the DataController's createNewTag,
///  createNewRenewal, and createNewCeActivity methods.
enum UpgradeNeeded: Error {
    case maxTagsReached
    case maxRenewalsReached
    case maxCeActivitiesReached
}

/// Enum for controlling what is shown to the user in the UpgradeToPaid sheet, depending on
/// whether the products from that AppStore have been loaded or if an erro has been thrown.
enum LoadState {
    case loading, loaded, error
}

// MARK: - SETTINGS
/// Enum used in DetailView for determining which view to show the user, depending on whether
/// they are editing a CeActivity and are navigating to the AcitivityReflectionView or if they are
/// accessing the app's settings page.
enum PageDestination: Hashable {
    case settings
    case reflection(ActivityReflection)
}

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

// MARK: - View Controls

/// Enum used in ActivityReflectionView and related sheets and sub-views for controlling
/// what set of reflection prompts are shown to the user.
///
/// Raw String values are as follows:
///     - builtInPrompts: "Standard Prompts"
///     - userMadePrompts: "Your Prompts"
///     - favoritePrompts: "Favorites"
///
///  - Note: Identifiable conformance is made via the raw value of each case
enum PromptView: String, CaseIterable, Identifiable, Hashable {
    case builtInPrompts = "Standard Prompts"
    case userMadePrompts = "Your Prompts"
    case favoritePrompts = "Favorites"
    
    var id: String { self.rawValue }
    
    
}//: ViewType

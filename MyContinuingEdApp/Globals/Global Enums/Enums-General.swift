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

// MARK: - FILE I/O

enum FileIOError: String, Error {
    case noError
    case writeFailed
    case fileMissing
    case unableToDelete
    case unableToMove
    case operationUnneeded
    case saveLocationUnavailable
    case loadingError
    case syncError
    case unknownError
    case cantIdentifyFileType
    case invalidArgument
    case noDirectoryAvailable
    case incompleteMove
    case metaDataUpdateError
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .noError:
            return ""
        case .writeFailed:
            return "The file could not be written to disk."
        case .fileMissing:
            return "The file could not be located."
        case .unableToDelete:
            return "The file could not be deleted for some reason."
        case .unableToMove:
            return "The file could not be moved to the requested location."
        case .operationUnneeded:
            return "The requested file operation is not neccesary, so it wasn't executed."
        case .saveLocationUnavailable:
            return "The specified location for saving the file is not a valid directory or filename (URL value)."
        case .loadingError:
            return "The file could not be loaded due to some error."
        case .syncError:
            return "The system was unable to sync the file."
        case .unknownError:
            return "An unspecified error has occured."
        case .cantIdentifyFileType:
            return "The file could not be identified as a known file type."
        case .invalidArgument:
            return "The file operation could not be completed due to an invalid value being used as part of the operation."
        case .noDirectoryAvailable:
            return "The specified directory for the file is either not valid or does not exist."
        case .incompleteMove:
            return "Part of the file was moved but an error or other process interrupted the move so it wasn't completely moved to the new location."
        case .metaDataUpdateError:
            return "The metadata for the file could not be updated correctly."
        case .invalidURL:
            return "The filepath (URL) provided for a specific file is not valid."
        }//: SWITCH
    }//: localizedDescription
}//: FileIOError

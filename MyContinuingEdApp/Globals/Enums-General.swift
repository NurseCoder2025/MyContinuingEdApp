//
//  Enums-General.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

import Foundation


// MARK: Enum for sheet types
enum SheetType {
    case renewal, issuer, specialCat
}


// MARK: Enum for credential types
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
    


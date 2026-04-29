//
//  UIViewEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import Foundation


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

/// Enum used in PromptResponseView to control whether the user enters a type-written response to a selected
/// prompt or if they choose to record an audio response (Pro subscribers only).
///
/// Raw String values are used as the id property and are as follows:
///     - writtenResponse: "Written Response"
///     - audioResponse: "Audio Response"
enum ResponseEntryType: String, CaseIterable, Identifiable, Hashable {
    case writtenResponse = "Written Response"
    case audioResponse = "Audio Response"
    
    var id: String { self.rawValue }
}//: ResponseEntryType

enum MediaLoadingState: String, CaseIterable {
    case noMedia, loading, loaded, error
}//: CertificateLoadingState

enum MediaCloudStatusIcon: String, CaseIterable {
    case noSavedMedia = "plus.circle.fill"
    case localOnly = "xmark.icloud"
    case localByPref = "gear.badge.xmark"
    case inICloud = "icloud.fill"
    case availableToDownload = "icloud.and.arrow.down.fill"
    case availableToUpload = "icloud.and.arrow.up"
    case cloudError = "exclamationmark.icloud.fill"
    case differentAppleID = "person.icloud.fill"
    case downloadingMedia = "arrow.triangle.2.circlepath"
    case cloudLimitReached = "lock.icloud.fill"
    case internetUnavailable = "wifi.slash"
    
    var labelText: String {
        switch self {
        case .noSavedMedia:
            return "Add a file"
        case .localOnly:
            return "Upgrade to sync with iCloud"
        case .localByPref:
            return "Change storage preference"
        case .inICloud:
            return "Saved to iCloud"
        case .availableToDownload:
            return "Download media file"
        case .availableToUpload:
            return "Upload media file to iCloud"
        case .cloudError:
            return "Error details"
        case .differentAppleID:
            return "Saved under a new AppleID account"
        case .downloadingMedia:
            return "Downloading..."
        case .cloudLimitReached:
            return "500MB limit reached"
        case .internetUnavailable:
            return "Device offline"
        }//: SWITCH
    }//: labelText
}//: MediaCloudStatusIcon


// MARK: - Enum for sheet types
enum SheetType {
    case renewal, issuer, specialCat
}//: SheetType

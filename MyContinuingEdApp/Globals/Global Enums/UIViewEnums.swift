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

enum SmartSyncStatusIcon: String, InfoIcon {
    case eligible = "checkmark.icloud"
    case restrictedToLocalDevice = "externaldrive.fill"
    case limitReached = "xmark.app"
    case noRenewalPeriod = "calendar.badge.plus"
    case noCurrentRenewal = "calendar.badge.exclamationmark"
    case transitionNotAcknowledged = "message.badge"
    case acknowledgeTransition = "checklist"
    case outsideOfSyncWindow = "clock.badge.xmark"
    case unspecifiedError = "exclamationmark.icloud.fill"
    case notApplicable = ""
    
    var userMessage: String {
        switch self {
        case .eligible:
            return "This certificate is currently eligible for SmartSync. Upload it to iCloud whenever desired."
        case .restrictedToLocalDevice:
            return "Only paid users of the app may utilize SmartSync. Please upgrade to a paid option in order to save your CE certificates to iCloud."
        case .limitReached:
            return "You have currently reached the max SmartSync limit for this renewal period. If you wish to upload this certificate, then you will need to select another certificate or certificates to remove from iCloud first."
        case .noRenewalPeriod:
            return "There are no renewal periods entered in this app currently. As a CE Cache Core user, the app must have renewal periods entered in order to determine SmartSync eligibility. You will not be able to upload anything until a renewal is entered."
        case .noCurrentRenewal:
            return "None of the renewal periods entered in the app are part of the current renewal period for your credential. Please add the new renewal period to the app so SmartSync can continue saving certificates earned for this period across your devices."
        case .transitionNotAcknowledged:
            return "The previous renewal period has ended but you have yet to acknowledge the renewal alert on the certificate list screen. Until you do so any new certificates will only be added locallyt to your device."
        case .acknowledgeTransition:
            return "The current renewal period will be ending soon. As a Core user, you must acknowledge this transition to ensure that your certificates are synced to iCloud."
        case .outsideOfSyncWindow:
            return "The certificate you are trying to upload is not within the current SmartSync sync window. However, as a Pro user you can either manually upload this certificate to iCloud or change the sync window value so that this certificate is included."
        case .unspecifiedError:
            return "An unknown error is preventing SmartSync from being able to upload the certificate. Please check your network connection, iCloud drive settings, SmartSync allowance usage, and that the current renewal period has been added to the app."
        case .notApplicable:
            return ""
        }//: SWITCH
    }//: userMessage
    
}//: SmartSyncStatusIcon


// MARK: - Enum for sheet types
enum SheetType {
    case renewal, issuer, specialCat
}//: SheetType

//
//  iCloudEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import CloudKit
import Foundation

// MARK: - MEDIA FILES
enum CertType: String, CaseIterable, Codable {case image, pdf, unspecified}
enum MediaType: String, CaseIterable, Codable {case image, pdf, audio, unspecified}
enum SaveLocation: String, Codable {case local, cloud, unknown}

enum CKAssetType: String, Codable {
    case certificate = "certificate"
    case audioReflection = "audio reflection"
    case transcription = "transcription"
}//: CKAssetType

enum MediaClass: String, CaseIterable, Codable {
    case certificate = "Certificate"
    case audioReflection = "Audio reflection"
    
    var pluralString: String {
        switch self {
        case .certificate:
            return "certificates"
        case .audioReflection:
            return "audio reflections"
        }
    }//: pluralString
}//: MediaClass

/// Global enum for providing the string identifier for CKRecord types. Values are either certificate or
/// audioReflection.
///
/// This enum was created in order to help prevent coding mistakes that would render invalid CKRecord
/// instances.
enum CkRecordType: String, CaseIterable {
    case certificate, audioReflection
}//: RecordTypes


// MARK: - iCLOUD

/// Enum that represents the possible statuses for the user's iCloud account: logged in but data
/// sync was disabled, logged in but iCloud unavailable, logged in with a different ID, or logged out.
///
/// Raw values for each case are a String and are used for the id property:
///     - loggedInNoSync: "Sync Disabled"
///     - loggedInUnavailable: "iCloud Unavailable"
///     - loggedInDifferentAppleID: "Different Apple ID"
///     - loggedOut: "Logged Out"
///
///  This enum also has a userMessage property which shows a different message for the user
///  for whichever status case applies.  This can be used in alerts and other UI elements.
enum iCloudStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case loggedInDisabled = "iCloud Disabled"
    case loggedInUnavailable = "iCloud Unavailable"
    case loggedINDifferentAppleID = "Different Apple ID"
    case loggedOut = "Logged Out"
    case noAccount = "No Account"
    case iCloudRestricted = "Restricted"
    case loggedIn = "Logged In"
    case unableToCheck = "Problem Checking"
    case needSyncingAccount = "Need Enabled iCloud Drive"
    case cantLogin = "Can't Login to iCloud"
    case incompatibleAppVersion = "Outdated App Version"
    case icloudDriveFull = "Storage Full"
    case initialStatus = "Initial"
    
    var id: String { self.rawValue }
    
    var userMessage: String {
        switch self {
        case .loggedInDisabled:
            "You currently have iCloud drive disabled. This app works best when iCloud sync is enabled, so please enable it now, unless you only want to store data on this device."
        case .loggedInUnavailable:
            "iCloud is currently unavailable, but since you are logged in the app will sync any changes in your data once it becomes available again."
        case .loggedINDifferentAppleID:
            "You are logged in to iCloud with a different Apple Account than what you previously were using.  Is this the account you want to sync data with?  Any data saved under the other Apple Account will not be available until you sign in with it again."
        case .loggedOut:
            "You are currently logged out of your iCloud account, so the app cannot sync data between devices. Before making any changes to the existing data, please sign back in again. Otherwise, any changes made will be saved to your local device only."
        case .noAccount:
            "Currently you do not have an iCloud account. This app works best with one, and Apple offers a limited free version of the service. If you wish to sync data on this device with other Apple products, then please use your Apple Account (formerly Apple ID) to sign in to the service so you can begin using it."
        case .iCloudRestricted:
            "Unfortunately, your iCloud account has been restricted either by the person managing your account or by Apple. Please check with them to gain access so you can sync data for this app on other Apple devices. Until this is resolved, you can only save data locally to this device."
        case .loggedIn:
            ""
        case .unableToCheck:
            "The app was unable to determine if you have an active iCloud account or not at this time. Ensure that you have a working internet connection and restart the app at a later time to check again. Until then, data can only be saved locally to your device."
        case .needSyncingAccount:
            "Either you don't currently have an iCloud account or you have disabled iCloud Drive for this device. If you want access to saved CE data on other Apple devices, then please enable iCloud drive or create an account. Otherwise, any new items will be saved to the local device only."
        case .cantLogin:
            "According to your device, you can't be logged into iCloud because either you don't have an account, have a restricted iCloud account, or have disabled iCloud Drive. Until iCloud Drive is enabled and you're logged in without restrictions, then the app will only save data locally to the device."
        case .incompatibleAppVersion:
            "You are running an out-of-date version of the app which can no longer sync with iCloud. Please update the app to continue using iCloud sync. Otherwise, CE data will be stored on this device only."
        case .icloudDriveFull:
            "You have met the limit of your iCloud Drive's storage capacity, so the app can no longer save any new data to it until you either upgrade your iCloud storage or free up space to allow for the saving of data from this app. Any new items will be saved to the local device only until space is available on your iCloud Drive again."
        case .initialStatus:
            ""
        }
    }//: UserMessage
    
    var iCloudIsAvailable: Bool {
        switch self {
        case .loggedINDifferentAppleID:
            return true
        case .loggedIn:
            return true
        default:
            return false
        }//: SWITCH
    }//: useLocalStorage
}//: iCloudStatus

/// Enum used to control whether CE certificates and audio recordings are saved locally or to iCloud.
/// Identifiable conformance by using each case as the id.
enum StorageToUse: Identifiable {
    case local, cloud
    
    var id: Self { self }
    
}//: storageToUse

enum UserCloudPrefKey: String, CaseIterable, Codable {
    case certsInCloud
    case audioInCloud
    case autoDownloadCerts
    case autoDownloadAudio
    case autoTranscription
    case smartSyncCertWindow
    
}//: userCloudPrefKeys

enum CloudSyncError: Error {
    case paidUpgradeNeeded
    case proLevelPurchaseNeeded
    case audioSyncProhibited
    case prefersLocalStorage(MediaClass)
    case cloudUnavailable
    case cloudSaveError(MediaClass)
    case mediaDeletionError(String)
    case cloudRecordNotFound(MediaClass)
    case genCloudRecNotFound
    case mediaDownloadFailed
    case basicCertLimitReached(Int)
    case noRenewalPeriodsSaved
    case noCurrentRenewalFound
    case syncLimitNotApplicable
    case smartSyncDateWindowError
    case smartSyncWindowCalcError
    case smartSyncCertOutOfWindow
    case smartSyncMaxWindowExceeded(Int)
    case querySubscriptionNotCreated
    
    var localizedDescription: String {
        switch self {
        case .paidUpgradeNeeded:
            return "In order to enjoy iCloud syncing of certificate and/or audio reflection files, please support the developer by making an in-app purchase."
        case .proLevelPurchaseNeeded:
            return "This feature is currently restricted to users who have purchased either a Pro Subscription or the Pro Lifetime in-app purchase. Upgrade today to enjoy all of the extra benefits!"
        case .audioSyncProhibited:
            return "You need to either have a Pro Subscription or the Pro Lifetime upgrade in order to enjoy unlimited iCloud syncing for audio reflections. Updgrade today!"
        case .prefersLocalStorage(let mediaType):
            return "You currently prefer to store all of your \(mediaType.pluralString) files locally. Change this by going into the Settings menu (in this app) and toggle the control to sync files with iCloud."
        case .cloudUnavailable:
            return "Unfortunately, access to your iCloud account isn't available due to one of many potential reasons. Please check your network connection, iCloud settings, and current iCloud drive storage capacity."
        case .cloudSaveError(let type):
            return "A technical iCloud-side error was encountered while trying to save the \(type.rawValue) data. Please try uploading it later."
        case .mediaDeletionError(let descript):
            return "The app was unable to delete the uploaded certificate file due to the following error: \(descript). Please try again later."
        case .cloudRecordNotFound(let type):
            return "The app was unable to locate the iCloud file for the \(type.rawValue) you are trying to download or delete. The file may have been deleted or moved. Please try again later."
        case .genCloudRecNotFound:
            return "The app was unable to locate the iCloud file for the media you are trying to download or delete. The file may have been deleted or moved. Please try again later."
        case .mediaDownloadFailed:
            return "The app could not move the downloaded media file to the proper location due to a technical error. Please try again and notify the developer if this continues to occur."
        case .basicCertLimitReached(let limit):
            return "You have reached the \(limit)MB limit for syncing certificates in iCloud. Upgrade to a Pro Subscription or the Pro Lifetime purchase in order to enjoy unlimited syncing for certificates + audio too!"
        case .noRenewalPeriodsSaved:
            return "Unable to find and load the current renewal period for your credential. Please add one in the CeCache home screen."
        case .noCurrentRenewalFound:
            return "Currently there is not a saved Renewal Period that includes today's date. Please add the starting and ending dates for whatever the current renewal period for your credential is in the CeCache home screen."
        case .syncLimitNotApplicable:
            return ""
        case .smartSyncDateWindowError:
            return "Due to either a missing completion date for the specified CE activity or an invalid sync window value, the app was not able to determine if the selected certificate can be synced to iCloud automatically. However, as a Pro user you manually upload it if you so choose."
        case .smartSyncWindowCalcError:
            return "The SmartSync feature was unable to calculate the starting point for the sync window due to a technical problem and so the certificate was not uploaded to iCloud automatically. However, you can do so manually if you'd like."
        case .smartSyncCertOutOfWindow:
            return "According to the window value you set, the selected certificate is too old to be synced to iCloud automatically. However, you can either adjust the window value in the app settings or manually upload it."
        case .smartSyncMaxWindowExceeded(let max):
            return "A value greater than the maximum number of years for SmartSync (\(max)) was used and so the certificate was not uploaded to iCloud automatically. However, you can do so manually if you'd like."
        case .querySubscriptionNotCreated:
            return "Unable to automatically delete or update media files on other files due to an iCloud sync setup error. The app will retry the setup process again."
        }//: SWITCH
    }//: localizedDescription
    
}//: CloudSyncError

enum CloudPrelimCheckError: String, CaseIterable, Identifiable, Hashable, Error {
    case iCloudAccessIssue
    case userNeedsToUpgrade
    case certsLocalOnly
    case audioLocalOnly
    case certsManDownload
    case audioManDownload
    
    var id: Self { self }
    
    var userMessage: String {
        switch self {
        case .iCloudAccessIssue:
            return "The app is unable to access your iCloud account due to one of many possible reasons. Please check that you are currently logged in, have network access, have iCloud drive enabled for this app, and do not have any restrictions placed on your account."
        case .userNeedsToUpgrade:
            return "In order to enjoy syncing media files such as CE certificates across your devices with iCloud, please make an in-app purchase today."
        case .certsLocalOnly:
            return "You currently want to save your CE certificates only on the device they were saved to. If you wish to sync them to other devices, please enable the option in the app settings."
        case .audioLocalOnly:
            return "You currently want to save your audio reflections only on the device they were saved to. If you wish to sync them to other devices, please enable the option in CeCache settings."
        case .certsManDownload:
            return "You currently want to manually download new CE certificates from other devices to the current one. If you wish for this to happen automatically, please enable the option in CeCache settings."
        case .audioManDownload:
            return "You currently want to manually download new audio reflection files from other devices to the current one. If you wish for this to happen automatically, please enable the option in CeCache settings."
        }//: SWITCH
    }//: userMessage
    
    var localizedDescription: String {
        switch self {
        case .iCloudAccessIssue:
            return "The app cannot access the user's iCloud account due to one of several potential reasons."
        case .userNeedsToUpgrade:
            return "The user is currently using CeCache Free and needs to make an in-app purchase in order to enjoy using media syncing in iCloud."
        case .certsLocalOnly:
            return "The user currently prefers to store certificates on their local device only per the value in the app settings."
        case .audioLocalOnly:
            return "The user currently prefers to store audio reflections on their local device only per the value in the app settings."
        case .certsManDownload:
            return "The user currently wants to manually download certificates on their other devices per app settings."
        case .audioManDownload:
            return "The user currently wants to manually download audio reflections on their other devices per app settings."
        }//: SWITCH
    }//: localizedDescription
}//: CloudPrelimCheckError


enum CloudDbSubStatus {
    case alreadyCreated
    case justAdded
}//: CloudDbSubStatus

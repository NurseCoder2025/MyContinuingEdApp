//
//  Collection+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import Foundation

extension Collection {
    
    /// Collection method that checks whether all user-facing settings are present in any given Collection
    /// (array, set, etc.) in order to ensure that all settings keys are updated and synced in iCloud.
    /// - Parameter keys: Collection of string values that correspond to a settings key
    /// - Returns: true if all string elements of the collection are not empty strings and the total number
    /// of elements is equal to the number within the String extension.
    ///
    /// Setting keys are used as part of the NSUbiquitousKeyValueStore, which is created in DataController.
    /// The file with the DataController extension, DataController-Settings, has computed properties that
    /// get and set the values for all of thse keys.  However, since adding or removing any of those
    /// properties also requires updating the handleKeyValueStoreChanges selector method (in the same
    /// extension), this method can be used to ensure that all settings keys have been updated.
    ///
    /// - Important: Whenever adding or removing a settings key, be sure to also add a static contstant
    /// to the String struct as well as to the allUserSettings set within this method.
    func allUserSettingsKeysPresent<T: Collection>(_ keys: T) -> Bool where T.Element == String {
        let allUserSettings: Set<String> = [
            String.firstRunKey,
            String.onBoardingKey,
            String.reminderAlertKey,
            String.purchaseStatusKey,
            String.primaryNotificationDaysKey,
            String.secondaryNotificationDaysKey,
            String.expiringCeNotificationKey,
            String.renewalEndingNotificationKey,
            String.renewalLateFeeNotificationKey,
            String.daiNotificationKey,
            String.liveEventAlertsKey,
            String.credentialReinstateAlertKey,
            String.firstLiveAlertKey,
            String.secondLiveAlertKey,
            String.tagBadgeIndicatorKey,
            String.storeAudioInCloudKey,
            String.storeCertsInCloudKey,
            String.autoDownloadCertsKey,
            String.autoAudioTranscriptionKey,
            String.autoDownloadAudioKey
        ]
        
        let allSettingsCount = allUserSettings.count
        
        return keys.allSatisfy(\.isEmpty) == false && allSettingsCount == keys.count
    }//: allUserSettingsKeysPresent()
    
}//: EXTENSION

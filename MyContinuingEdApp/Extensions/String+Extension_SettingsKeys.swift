//
//  String+Extension_SettingsKeys.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import Foundation

// The puropose of this file is to hold String static constants for all
// settings in the app that are synced across devices

extension String {
    
    static let onBoardingKey: String = "showOnboardingScreen"
    static let reminderAlertKey: String = "showReminderAlert"
    static let purchaseStatusKey: String = "purchaseStatus"
    static let primaryNotificationDaysKey: String = "primaryNotificationDays"
    static let secondaryNotificationDaysKey: String = "secondaryNotificationDays"
    static let expiringCeNotificationKey: String =  "showExpiringCesNotifications"
    
    static let renewalEndingNotificationKey: String = "showRenewalEndingNotifications"
    
    static let renewalLateFeeNotificationKey: String = "showRenewalLateFeeNotifications"
    
    static let daiNotificationKey: String =  "showDAINotifications"
    static let liveEventAlertsKey: String =  "showAllLiveEventAlerts"
    
    static let credentialReinstateAlertKey: String = "showCredentialReinstatementAlerts"
    
    static let firstLiveAlertKey: String = "firstLiveEventAlert"
    static let secondLiveAlertKey: String = "secondLiveEventAlert"
    static let tagBadgeIndicatorKey: String =  "tagBadgeCountOf"
    
    static let firstRunKey: String = "isFirstRun"
    
    static let askForReviewKey: String = "requestReviewCount"
    
    static let storeCertsInCloudKey: String = "prefersCertificatesInICloud"
    static let storeAudioInCloudKey: String = "prefersAudioReflectionsInICloud"
    
    static let autoAudioTranscriptionKey: String = "allowsAutoTranscriptionOfAudio"
    
    static let autoDownloadCertsKey: String = "autoDownloadCertificates"
    static let autoDownloadAudioKey: String = "autoDownloadAudioReflections"
    
    static let smartSyncCertDownloadWindowKey: String = "smartSyncCertDownloadWindow"
    
    static let cloudDBSubscriptionCreatedKey: String = "cloudDbSubscriptionCreated"
    
}//: EXTENSION



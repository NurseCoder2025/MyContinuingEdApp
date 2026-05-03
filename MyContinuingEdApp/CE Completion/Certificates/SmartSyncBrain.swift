//
//  SmartSyncBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/29/26.
//

import CloudKit
import CoreData
import Foundation


final class SmartSyncBrain: ObservableObject {
    // MARK: - PROPERTIES
    
    private let settings = AppSettingsCache.shared
    private let mediaBrain = CloudMediaBrain.shared
    private let masterList = MasterMediaList.shared
    
    let currentAllowanceTotal: Double = Double.maxCertAllowance
    let defaultRenewalWindow: Int = 90
    
    enum SmartSyncAllowanceWarning {
        case nearLimit, reachedLimit
    }//: SmartSyncAllowanceWarning
    var allowanceLimitAlertType: SmartSyncAllowanceWarning = .nearLimit
    
    // SmartSync Error Details for user
    @Published var smartSyncErrorDetails: String = ""
    @Published var smartSyncErrorIcon: SmartSyncStatusIcon = .notApplicable
    
    // Alerts
    @Published var showAllowanceWarningAlert: Bool = false
   
    // Renewal Message
    @Published var renewalWindowWarningBoxMessage: String = ""
    @Published var renewalPeriodNeedsAdded: Bool = false
    @Published var renewalWarningBoxIsShowing: Bool = false
    @Published var userIsPastRenewalWithoutAcknowledgement: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    var userIsACoreUser: Bool { userPaidSupportLevel == .basicUnlock }//: userIsACoreUser
    
    var currentAllowanceUsage: Double { settings.allowanceUsed }//: currentAllowanceUsage
    
    var userHasReachedMaxAllowance: Bool {
        guard settings.getCurrentPurchaseLevel() == .basicUnlock else { return false }//: GUARD
        
        return currentAllowanceUsage >= currentAllowanceTotal
    }//: userHasExceededMaxAllowance
    
    var showAllowanceWarning: Bool {
        guard settings.getCurrentPurchaseLevel() == .basicUnlock else {
            return false
        }//: GUARD
        
        return currentAllowanceUsage >= (currentAllowanceTotal * 0.8)
    }//: showAllowanceWarning
    
    var allowanceUsagePercentage: String {
        ((currentAllowanceUsage / currentAllowanceTotal) * 100).formatted(.percent)
    }//: allowanceUsagePercentage
    
    // MARK: LIMIT ALERTS
    var allowanceLimitAlertTitle: String {
        switch allowanceLimitAlertType {
        case .nearLimit:
            return "SmartSync Limit Warning"
        case .reachedLimit:
            return "SmartSync Limit Reached"
        }//: SWITCH
    }//: allowanceLimitAlertTitle
    
    var allowanceLimitAlertMessage: String {
        switch allowanceLimitAlertType {
        case .nearLimit:
            return "You are currently at \(allowanceUsagePercentage)% of your SmartSync allowance of \(currentAllowanceTotal) MB as a CE Cache Core user. Upgrade to a Pro plan today for unlimited SmartSync! You can also remove unwanted certificates off of iCloud to free up space for other certificates. Otherwise, new certificates will only be saved to a single device after the allowance is reached."
        case .reachedLimit:
            return "You have current reached the allowance of \(currentAllowanceTotal) MB as a CE Cache Core user. Upgrade to a Pro plan today for unlimited SmartSync! You can also remove unwanted certificates off of iCloud to free up space for other certificates. Otherwise, new certificates will only be saved to a single device going forward."
        }//: SWITCH
    }//: approachingLimitAlertMessage
    
   
    
    // MARK: - SINGLETON
    
    static let shared = SmartSyncBrain()
    
    // MARK: - METHODS
    
    func updateSmartSyncUsage(for certInfo: CertificateInfo) {
        guard userPaidSupportLevel == .basicUnlock else { return }//: GUARD
        let uploadedCertSize = certInfo.fileSizeInMegabytes
        if certInfo.uploadedToICloud {
            settings.updateSmartSyncAllowanceUsed(by: uploadedCertSize)
        } else {
            // This assumes the certificate was previously uploaded to iCloud
             let certRec = certInfo.certCloudRecordName
            // TODO: Make sure newly uploaded certs are added to the MasterList & not deleted prior to this check
            if certRec.recordName != String.mediaIdPlaceholder, masterList.hasRecord(withID: certRec) {
                settings.decreaseSmartSyncAllowanceUsed(by: uploadedCertSize)
            }//: IF (recordName != .mediaIdPlaceholder, hasRecord)
        }//: IF ELSE (uploadedToICloud)
        
        if userHasReachedMaxAllowance {
            allowanceLimitAlertType = .reachedLimit
        } else if showAllowanceWarning {
            allowanceLimitAlertType = .nearLimit
        }//: IF ELSE (userHasReachedMaxAllowance)
    }//: certSyncedFollowUp()
    
    func shouldAllowCertUpload(for certInfo: CertificateInfo) -> Bool {
        guard userIsACoreUser else { return true }
        
        let smartSyncElibilityResult = certInfo.isCertEligibleForSmartSync(syncWindow: settings.smartSyncCertWindow)
        switch smartSyncElibilityResult {
        case .success(_):
            return (userIsPastRenewalWithoutAcknowledgement ? false : true)
        case .failure(let syncError):
            smartSyncErrorDetails = syncError.localizedDescription
            return false
        }//: SWITCH
    }//: shouldAllowCertUpload
    
    /// This SmartSyncBrain method returns a String value representing a message to the user explaining why
    /// the current certificate is not eligible for SmartSync.
    /// - Parameter cert: CertificateInfo object representing the certificate being viewed by the user
    /// - Returns: A String value with details corresponding to the specific reason why the certificate cannot be
    /// uploaded to iCloud
    ///
    /// - Note: Even though only CE Cache Core users have limits placed on their SmartSync usage techincally,
    /// Pro users may still encounter times when a certificate is not found to eligible only because it is assigned to
    /// a CE activity that falls outside of the sync window value that they set. In this situation, they will be alerted to
    /// that fact but given the option to manually upload the certificate to iCloud if they so choose (they can also update
    /// the sync window value as well).
    ///
    /// This method actually does two things: first, it updates the SmartSyncBrain @Published property
    /// smartSyncErrorIcon (with the proper SmartSyncStatusIcon enum value) and returns a String value based
    /// on the enum being assigned to the smartSyncErrorIcon property (via the userMessage computed property within
    /// the enum).  If the cert argument happens to meet all of the SmartSync eligibility criteria, then an empty
    /// string is returned.
    func getSmartSyncIneligibilityReason(for cert: CertificateInfo) -> String {
        var reason: String = ""
        smartSyncErrorIcon = .notApplicable
        
        let smartSyncElibilityResult = cert.isCertEligibleForSmartSync(syncWindow: settings.smartSyncCertWindow)
        switch smartSyncElibilityResult {
        case .success(_):
            if userIsPastRenewalWithoutAcknowledgement {
                smartSyncErrorIcon = .transitionNotAcknowledged
                reason = smartSyncErrorIcon.userMessage
            }//: IF (userIsPastRenewalWithoutAcknowlegement)
        case .failure(let syncError):
            smartSyncErrorDetails = syncError.localizedDescription
            if syncError == CloudSyncError.basicCertLimitReached {
                smartSyncErrorIcon = .limitReached
                reason = smartSyncErrorIcon.userMessage
            } else if syncError == CloudSyncError.noRenewalPeriodsSaved {
                smartSyncErrorIcon = .noRenewalPeriod
                reason = smartSyncErrorIcon.userMessage
            } else if syncError == CloudSyncError.noCurrentRenewalFound {
                smartSyncErrorIcon = .noCurrentRenewal
                reason = smartSyncErrorIcon.userMessage
            } else {
                smartSyncErrorIcon = .unspecifiedError
                reason = smartSyncErrorDetails
            }//: IF ELSE
        }//: SWITCH
        return reason
    }//: getSmartSyncIneligibilityReason
    
    func shouldShowRenewalWarningBox(using cred: Credential?) -> Bool {
        guard userIsACoreUser else { return false } //: GUARD
        
        let today = Date.now.standardizedDate
        let needUserAcknowledgement = settings.userToAcknowledgeRenewalEnding
        
        if let enteredCred = cred, let renewEndsOn = enteredCred.currentRenewalEndsOn {
            if isTodayWithinRenewalWindow(basedOn: renewEndsOn), needUserAcknowledgement {
                let daysRemaining = calculateDaysRemainingUntilRenewalEnds(basedOn: renewEndsOn)
                setRenewalWarningBoxText(using: daysRemaining, usingDefaultRenewal: false, defaultEndDate: nil)
                renewalWarningBoxIsShowing = true
                return true
            } else if !isTodayWithinRenewalWindow(basedOn: renewEndsOn),
                let previousRenew = enteredCred.getPreviousRenewalPeriod(),
                !previousRenew.hasUserAcknowledgedWarning {
                let daysRemaining = calculateDaysRemainingUntilRenewalEnds(basedOn: previousRenew.renewalPeriodEnd)
                setRenewalWarningBoxText(using: daysRemaining, usingDefaultRenewal: false, defaultEndDate: nil)
                renewalWarningBoxIsShowing = true
                userIsPastRenewalWithoutAcknowledgement = true
                return true
            } else {
                renewalWarningBoxIsShowing = false
                return false
            }//: IF (isTodayWithinRenewalWindow, !userAcknowledged)
        } else {
            // If there is not a current renewal period or the current renewal then no need
            // to show anything - a separate box alerting the user to create a renewal period will
            // be displayed by the respective view model.
            // However, SmartSync for Core users without any entered renewals should be blocked until
            // data by the user is entered, so setting the userIsPastRenewalWithoutAcknowledgement to
            // true in this situation.
            userIsPastRenewalWithoutAcknowledgement = true
            return false
        }//: IF LET (enteredCred, renewEndsOn)
    }//: shouldShowRenewalWarningBox()
    
    private func isTodayWithinRenewalWindow(basedOn endDate: Date, window: Int = 90) -> Bool {
        let calendar = Calendar.current
        let today = Date.now.standardizedDate
        
        let startingValue = -window
        
        if let windowStartDate = calendar.date(byAdding: .day, value: startingValue, to: endDate) {
            return windowStartDate <= today && today <= endDate
        } else {
            return false
        }//: IF LET (windowStartDate)
    }//: isTodayWithinRenewalWindow()
    
    private func isTodayPastRenewalWindow(basedOn endDate: Date, window: Int = 90) -> Bool {
        let standardEndDate = endDate.standardizedDate
        let today = Date.now.standardizedDate
        
        return today > standardEndDate
    }//: isTodayPastRenewalWindow(basedOn, window)
    
    private func calculateDaysRemainingUntilRenewalEnds(basedOn endDate: Date) -> Int {
        let calendar = Calendar.current
        let today = Date.now.standardizedDate
        
        if let daysRemaining = calendar.dateComponents([.day], from: today, to: endDate).day {
            return daysRemaining
        } else {
            return 0
        }//: IF LET (daysRemaining)
    }//: calculateDaysRemainingUntilRenewalEnds(basedOn)
    
    private func setRenewalWarningBoxText(
        using daysRemaining: Int,
        usingDefaultRenewal: Bool,
        defaultEndDate: Date?
    ) {
        if usingDefaultRenewal, let endDate = defaultEndDate {
            let formattedEnd = endDate.formatted(date: .abbreviated, time: .omitted)
            renewalWindowWarningBoxMessage = """
            There aren't any dates from which to determine what the current renewal period for you is, so a set of reasonable values are being used to simulate one. These values are based on a 2 year renewal cycle which started on the day you first began using this app. 
            
            According to those values, there are only \(daysRemaining) days left until the "current renewal" ends on \(formattedEnd). Because the CE Cache Core plan focuses on the CE data that matters the most to you, only certificates for whatever is the current renewal period will sync across your devices in iCloud. 
            
            Once the end date arrives, copies of certificates from this renewal will be removed from iCloud and no longer sync. You will need to add a renewal period with date values correpsonding to the one you'll be in so you can sync certificates going forward at that point. If you need greater functionality and the ability to sync certificates for a longer time range, upgrade to a CE Cache Pro plan before \(formattedEnd) to keep those certificates in iCloud.
            """
        } else if usingDefaultRenewal {
            renewalWindowWarningBoxMessage = """
            There aren't any dates from which to determine what the current renewal period for you is, so a set of reasonable values are being used to simulate one. These values are based on a 2 year renewal cycle which started on the day you first began using this app. 
            
            According to those values, there are only \(daysRemaining) days left until the "current renewal" ends. Because the CE Cache Core plan focuses on the CE data that matters the most to you, only certificates for whatever is the current renewal period will sync across your devices in iCloud. 
            
            Once there are 0 days left, copies of certificates from this renewal will be removed from iCloud and no longer sync to your other devices. You will need to add a renewal period with date values so you can sync certificates going forward at that point. If you need greater functionality and the ability to sync certificates for a longer time range, upgrade to a CE Cache Pro plan to keep those certificates in iCloud.
            """
        } else if daysRemaining < 0 {
            renewalWindowWarningBoxMessage = """
            According to the renewal period data within this app, the current renewal for your credential ended \(daysRemaining.absValue) days ago. Because the CE Cache Core plan focuses on the CE data that matters the most to you, only certificates for whatever is the current renewal period will sync across your devices in iCloud. 
            
            If CE Cache Core functionality meets your needs, simply acknowledge this message and the certificates from the previous renewal will be removed off of iCloud so you can begin syncing ones for the new period. If you need greater functionality and the ability to sync certificates for a longer time range, upgrade to a CE Cache Pro plan today!
            """
        } else {
            renewalWindowWarningBoxMessage = """
            There are only \(daysRemaining) days left until the current renewal period ends. Because the CE Cache Core plan focuses on the CE data that matters the most to you, only certificates for whatever is the current renewal period will sync across your devices in iCloud. 
            
            Because your CE certificates are important to your professional career, please acknowledge this message prior to the renewal's end as a way of letting the app know that this Core feature still meets your needs (note that a local copy of each certificate will remain on the device you make the acknowledgement from). Once the acknowlegement is received, SmartSync for the next renewal will be enabled. 
            
            If you need greater functionality and the ability to sync certificates for a longer time range, upgrade to a CE Cache Pro plan before the current renewal ends to keep those certificates in iCloud.
            """
        }//: IF ELSE (usingDefaultRenewal)
    }//: setRenewalWarningBoxText
    
    // MARK: - INIT
    
    private init() {
        
    }//: INIT
    
}//: CLASS

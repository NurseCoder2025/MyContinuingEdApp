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
    
    enum SmartSyncAllowanceWarning {
        case nearLimit, reachedLimit
    }//: SmartSyncAllowanceWarning
    var allowanceLimitAlertType: SmartSyncAllowanceWarning = .nearLimit
    
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
        case .failure(_):
            return false
        }//: SWITCH
    }//: shouldAllowCertUpload
    
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
            // If there is not a current renewal period or the current renewal has no end date
            // create an aribtrary "fake" renewal period for the purpose of syncing a limited
            // number of certificates for Core users
            let defaultRenewalStartDate = settings.settingsStartDate.standardizedDate
            let defaultRenewalEndDate = defaultRenewalStartDate.addingTimeInterval(86400 * 730)
            
            if isTodayWithinRenewalWindow(basedOn: defaultRenewalEndDate) && needUserAcknowledgement {
                let daysRemaining = calculateDaysRemainingUntilRenewalEnds(basedOn: defaultRenewalEndDate)
                setRenewalWarningBoxText(using: daysRemaining, usingDefaultRenewal: true, defaultEndDate: defaultRenewalEndDate)
                renewalPeriodNeedsAdded = true
                renewalWarningBoxIsShowing = true
                return true
            } else if isTodayPastRenewalWindow(basedOn: defaultRenewalEndDate) && needUserAcknowledgement {
                userIsPastRenewalWithoutAcknowledgement = true
                renewalWarningBoxIsShowing = true
                let daysRemaining = calculateDaysRemainingUntilRenewalEnds(basedOn: defaultRenewalEndDate)
                setRenewalWarningBoxText(using: daysRemaining, usingDefaultRenewal: true, defaultEndDate: defaultRenewalEndDate)
                return true
            } else {
                renewalWarningBoxIsShowing = false
                return false
            }//: IF (isTodayWithinRenewalWindow)
        }//: IF LET (enteredCred, renewEndsOn)
    }//: shouldShowRenewalWarningBox()
    
    private func isTodayWithinRenewalWindow(basedOn endDate: Date, window: Int = 60) -> Bool {
        let calendar = Calendar.current
        let today = Date.now.standardizedDate
        
        let startingValue = -window
        
        if let windowStartDate = calendar.date(byAdding: .day, value: startingValue, to: endDate) {
            return windowStartDate <= today && today <= endDate
        } else {
            return false
        }//: IF LET (windowStartDate)
    }//: isTodayWithinRenewalWindow()
    
    private func isTodayPastRenewalWindow(basedOn endDate: Date, window: Int = 60) -> Bool {
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
    
}//: CLASS

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
    
    @Published var showAllowanceWarningAlert: Bool = false
    @Published var currentRenewalEndsDate: Date? = nil
    
    
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
        let currentDate = Date.now.standardizedDate
        let acknowledgementNeeded = settings.userToAcknowledgeRenewalEnding
        
        let smartSyncElibilityResult = certInfo.isCertEligibleForSmartSync(syncWindow: settings.smartSyncCertWindow)
        switch smartSyncElibilityResult {
        case .success(_):
            if let periodEndedOn = settings.renewalEndDate,
                currentDate > periodEndedOn,
                acknowledgementNeeded {
                return false
            } else if !acknowledgementNeeded {
                return true
            }
        case .failure(_):
            return false
        }//: SWITCH
        
    }//: shouldAllowCertUpload
    
    
    // MARK: - INIT
    
}//: CLASS

//
//  DataController-SmartSync.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CoreData
import Foundation


extension DataController {
    
    func areThereUploadedCertsOutsideCurrentRenewal() -> (certsOutside: Bool, certs: [CertificateInfo]) {
        guard userPaidSupportLevel == .basicUnlock else {return (false, [])}//: GUARD
        let context = container.viewContext
        
        var certCheckResult: Bool = false
        var uploadedCertsNotInCurrentPeriod: [CertificateInfo] = []
        
        // Check to see if there even is a current renewal period, and if so,
        // use that to filter out all certificates that have been uploaded for a
        // different renewal period
        if let currentRenewal = getCurrentRenewalPeriods().first {
            let renewalFetch = RenewalPeriod.fetchRequest()
            renewalFetch.sortDescriptors = [NSSortDescriptor(key: "periodEnd", ascending: true)]
            
            let allRenewals = (try? context.fetch(renewalFetch)) ?? []
            let nonCurrentRenewals = allRenewals.filter { $0 != currentRenewal }
            for renewal in nonCurrentRenewals {
                let uploadedCerts = renewal.getAllUploadedCertificates()
                uploadedCertsNotInCurrentPeriod.append(contentsOf: uploadedCerts)
            }//: LOOP
            if uploadedCertsNotInCurrentPeriod.isNotEmpty {
                certCheckResult = true
            }//: IF (uploadedCertsNotInCurrentPeriod)
        } else {
            // Even if there is no current renewal period, there still might be older
            // or even future renewals that have been entered.  If so, then for each
            // of those simply find all certificates that have been uploaded for each.
            let renewalFetch = RenewalPeriod.fetchRequest()
            renewalFetch.sortDescriptors = [NSSortDescriptor(key: "periodEnd", ascending: true)]
            
            let allRenewals = (try? context.fetch(renewalFetch)) ?? []
            guard allRenewals.isNotEmpty else { return (false, []) }//: GUARD
            
            for renewal in allRenewals {
                let uploadedCerts = renewal.getAllUploadedCertificates()
                uploadedCertsNotInCurrentPeriod.append(contentsOf: uploadedCerts)
            }//: LOOP
            
            if uploadedCertsNotInCurrentPeriod.isNotEmpty {
                certCheckResult = true
            }//: IF (uploadedCertsNotInCurrentPeriod.isNotEmpty)
            
        }//: IF LET (getCurrentRenewalPeriods().first)
        
        return (certCheckResult, uploadedCertsNotInCurrentPeriod)
    }//: areThereUploadedCertsOutsideCurrentRenewal()
    
    
    func saveCurrentRenewalEndingDatesInSettings(warningStarts daysAhead: Int = 60) {
        guard userPaidSupportLevel == .basicUnlock else { return } //: GUARD

        let settings = AppSettingsCache.shared
        
        if let endingDate = getCurrentRenewalEndDate() {
            settings.setCurrentRenewalEndDate(endingDate)
        }//: IF LET (endingDate)
        
        if let windowDate = getRenewalWarningWindowStartDate(daysAhead: daysAhead) {
            settings.setCurrentRenewalWarningWindowDate(windowDate)
        }//: IF LET (windowDate)
    }//: saveCurrentRenewalEndingDatesInSettings(daysAhead)
    
    func getRenewalWarningWindowStartDate(daysAhead: Int = 60) -> Date? {
        guard userPaidSupportLevel == .basicUnlock else { return nil }//: GUARD
        guard let currentRenewal = getCurrentRenewalPeriods().first, let currentEnds = currentRenewal.periodEnd else { return nil }//: GUARD
        
        let settings = AppSettingsCache.shared
        let calendar = Calendar.current
        let daysToSubtract: Int = -daysAhead
        
        let standardEndDate = currentEnds.standardizedDate
        let windowStartDate = calendar.date(byAdding: .day, value: daysToSubtract, to: standardEndDate)
        
        return windowStartDate?.standardizedDate
    }//: getRenewalWarningWindowStartDate(daysAhead)
    
    func getCurrentRenewalEndDate() -> Date? {
        guard let currentRenewal = getCurrentRenewalPeriods().first, let currentEnds = currentRenewal.periodEnd else { return nil }
        return currentEnds.standardizedDate
    }//: getCurrentRenewalEndDate()
    
    
   
    
}//: DATA CONTROLLER

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
        }//: IF LET (getCurrentRenewalPeriods().first)
        
        return (certCheckResult, uploadedCertsNotInCurrentPeriod)
    }//: areThereUploadedCertsOutsideCurrentRenewal()
    
    
    func setRenewalWarningReferenceDate(daysAhead: Int = 30) {
        guard userPaidSupportLevel == .basicUnlock else { return } //: GUARD
        guard let currentRenewal = getCurrentRenewalPeriods().first,
              let currentEndsOn = currentRenewal.periodEnd else {
            let settings = AppSettingsCache.shared
            settings.setCurrentRenewalEndDate(nil)
            settings.setCurrentRenewalReferenceDate(nil)
            return
        } //: GUARD
        
        let settings = AppSettingsCache.shared
        guard settings.userToAcknowledgeRenewalEnding else {
            settings.setCurrentRenewalReferenceDate(nil)
            return
        } //: GUARD
        
        let calendar = Calendar.current
        let currentDate = Date.now.standardizedDate
        let daysInTimeInterval: TimeInterval = Double(daysAhead * 24 * 60 * 60)
        
        if currentEndsOn.timeIntervalSince(currentDate) >= daysInTimeInterval {
            if let targetRefDate = calendar.date(byAdding: .second, value: Int(daysInTimeInterval), to: currentEndsOn)?.standardizedDate {
                settings.setCurrentRenewalReferenceDate(targetRefDate)
            }//: IF LET (targetRefDate)
        } else if currentEndsOn.timeIntervalSince(currentDate) >= 0 {
            let targetRefDate = currentDate
            settings.setCurrentRenewalReferenceDate(targetRefDate)
        } else {
            return
        }//: IF ELSE (timeIntervalSince)
    }//: setRenewalWarningReferenceDate(daysAhead)
   
    
}//: DATA CONTROLLER

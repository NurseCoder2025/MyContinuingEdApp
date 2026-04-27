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
        guard purchaseStatus == PurchaseStatus.basicUnlock.id else {return (false, [])}//: GUARD
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
    
    
   
    
}//: DATA CONTROLLER

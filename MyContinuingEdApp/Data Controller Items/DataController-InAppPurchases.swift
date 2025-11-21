//
//  DataController-InAppPurchases.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/20/25.
//

import Foundation


extension  DataController {
    
    /// Computed property that returns the number of RenewalPeriod objects currently stored in
    /// the view context.
    var currentNumberOfRenewals: Int {
        let context = container.viewContext
        let renewalsFetch = RenewalPeriod.fetchRequest()
        let renewals: [RenewalPeriod] = (try? context.fetch(renewalsFetch)) ?? []
        return renewals.count
    }//: currentNumberOfRenewals
    
}//: DATA CONTROLLER

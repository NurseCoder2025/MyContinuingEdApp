//
//  DataController-Automation.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large size of the DataController class, separating out functions with similar
// functionality in order to improve code organization and readability.

import CoreData
import Foundation


extension DataController {
    // MARK: - Automation Related Methods
    
    /// Function that finds the appropriate renewal period for each CE activity, if applicable, and assigns the activity to that period. The activity
    /// must be completed and have a dateCompleted value in order to be assigned to a renewal period.
    func assignActivitiesToRenewalPeriod() {
        let viewContext = container.viewContext
        
        // Fetching only all completed CE Activities
        let activityRequest: NSFetchRequest<CeActivity> = CeActivity.fetchRequest()
        activityRequest.predicate = NSPredicate(format: "activityCompleted = true")
        let allCompletedActivities = (try? viewContext.fetch(activityRequest)) ?? []
        
        // Fetching all credentials
        let credentialRequest: NSFetchRequest<Credential> = Credential.fetchRequest()
        let allCredentials = (try? viewContext.fetch(credentialRequest)) ?? []
        
        // Fetching all renewal periods
        let renewalRequest: NSFetchRequest<RenewalPeriod> = RenewalPeriod.fetchRequest()
        let allRenewals = (try? viewContext.fetch(renewalRequest)) ?? []
        
        guard allCredentials.isNotEmpty, allRenewals.isNotEmpty else { return }
        
        for activity in allCompletedActivities {
            guard let completedDate = activity.dateCompleted else { continue }
            
            // Find the credential(s) for this activity
            let activityCredentials = activity.credentials as? Set<Credential> ?? []
            
            for credential in activityCredentials {
                // Cast renewals to Set<RenewalPeriod> for type-safe access
                if let renewalsSet = credential.renewals as? Set<RenewalPeriod> {
                    if let matchingRenewal = renewalsSet.first(where: { renewal in
                        guard let start = renewal.periodStart, let end = renewal.periodEnd else { return false }
                        return start <= completedDate && completedDate <= end
                    }) {
                        activity.renewal = matchingRenewal
                        break // Found a match, no need to check other credentials
                    } else {
                        activity.renewal = nil
                    }
                }
            }
        }
        save()
    }
    
    
    
    
}//: DataController

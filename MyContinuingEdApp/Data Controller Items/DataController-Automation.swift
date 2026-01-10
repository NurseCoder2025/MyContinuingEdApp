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
    
    /// Function that finds the appropriate renewal periods for each CE activity, if applicable, and assigns the activity to those periods.
    /// The activity must be completed and have a dateCompleted value in order to be assigned to a renewal period.
    ///
    /// This method will assign all completed CeActivity objects to all RenewalPeriods where the completion date falls between
    /// the starting and ending dates (inclusive of those as well) for each Credential that the CeActivity object was assigned to in
    /// ActivityView.  Note that there should only be one RenewalPeriod assignment per Credential object.
    func assignActivitiesToRenewalPeriods() {
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
                // Find a matching renewal period for each credential the activity is assigned to
                if let renewalsSet = credential.renewals as? Set<RenewalPeriod> {
                    if let matchingRenewal = renewalsSet.first(where: { renewal in
                        guard let start = renewal.periodStart, let end = renewal.periodEnd else { return false }
                        return start <= completedDate && completedDate <= end
                    }) {
                        activity.addToRenewals(matchingRenewal)
                    } //: IF LET (matchingRenewal)
                }//: IF LET (renewalsSet)
            }//: LOOP (credential in activityCredentials)
            
        }//: LOOP (activity in allCompletedActivities)
        save()
    } //: assignActivitiesToRenewalPeriod()
    
    
    
    
}//: DataController

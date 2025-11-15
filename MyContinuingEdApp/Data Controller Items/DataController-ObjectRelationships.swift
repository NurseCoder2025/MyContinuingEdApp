//
//  DataController-ObjectRelationships.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

// Purpose: To hold functions and computed properties that retrieve all or specific child objects for entities
// having a many to many or one to many relationship.

import CoreData
import Foundation


extension DataController {
    
    /// Function for retrieving all SpecialCategory objects associated with a given Credential and RenewalPeriod
    /// - Parameter renewal: RenewalPeriod for which special categories are needed
    /// - Returns: Array of SpecialCategory objects assigned to the RenewalPeriod's Credential
    func getAllSpecialCatsFor(renewal: RenewalPeriod) -> [SpecialCategory] {
        if let renewalCred = renewal.credential {
            if let assignedSpecialCats = renewalCred.specialCats as? Set<SpecialCategory> {
               let catArray = Array(assignedSpecialCats)
               return catArray
            }
        }//: IF LET
        return []
    }//: getAllSpecialCatsFor()
    
}//: DataController

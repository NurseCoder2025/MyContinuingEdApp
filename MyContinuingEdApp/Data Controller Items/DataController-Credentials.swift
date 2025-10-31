//
//  DataController-Credentials.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

import CoreData
import Foundation


extension DataController {
    //: MARK: - Credentials Related Methods
    /// This function counts the number of credentials of a given type that have been entered  into the app and returns the number as an Int
    /// that can be passed into the CredentialCatBoxView for display as a badge icon.
    /// **Important:**
    /// the type parameter is assumed to be a  credential type in the plural form (i.e. Licenses, Certifications, etc.) except for "All" which is singular.
    /// If this function is used outside of the CredentialManagementSheet struct (which is where plural forms of credential types are being passed in)
    /// then the function needs to be updated so that singular forms aren't trimmed.
    /// - Parameter type: credential type (String value) - see Credential-CoreDataHelper for extension with String array that holds these values
    /// - Returns: whole number (Int) representing the number of credentials of a specific type stored in persistent storage
    func getNumberOfCredTypes(type: String) -> Int {
        let request = Credential.fetchRequest()
        if type != "all" && type != "" {
            request.predicate = NSPredicate(format: "credentialType == %@", type)
        }
        let count = (try? container.viewContext.count(for: request)) ?? 0
        return count
    }
    
    /// Using a multi-level predicate, this function determines which credentials are currently considered to be encumbered.  The crieteria are as follows:
    ///    1. The credential's isRestricted property is true OR
    ///    2. Disciplinary action has been taken against the credential which is either permanent or has not ended yet AND
    ///    3. The disciplinary action has NOT been appealed.
    /// - Returns: Array of all Credential objects that meet the specified predicate criteria
    func getEncumberedCredentials() -> [Credential] {
        let credFetch = Credential.fetchRequest()
               
        // Predicates for determining if a credential is, indeed, encumbered
        // Credential restriction property predicate
        let restrictionPredicate = NSPredicate(format: "isRestricted == true")
        
        
        // Related disciplinary action predicates
        // The next three predicates are ORed together to determine if any of them are true
        var currentDAIPredicates: [NSPredicate] = []
        // If the disciplinary action end date is not in the past then include it
        let openDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.actionEndDate > %@", Date.now as NSDate)
        currentDAIPredicates.append(openDisciplinaryActionPredicate)
        // Alternatively, if there is no end date for the disciplinary action, include it
        let noEndDateDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.actionEndDate == nil")
        currentDAIPredicates.append(noEndDateDisciplinaryActionPredicate)
        // If the disciplinary action is permanent then also include it
        let permanentDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.temporaryOnly == false")
        currentDAIPredicates.append(permanentDisciplinaryActionPredicate)
        
        // Compound predicate holding the three predicates related to actionEndDate or temporaryOnly properties
        let daiORCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: currentDAIPredicates)
        
        // Adding credential ONLY if action has NOT been appealed
        let notAppealedPredicate = NSPredicate(format: "ANY disciplinaryActions.appealedActionYN == false")
        
        // Creating a compound predicate (AND) with the daiORCompoundPredicate and the notAppealedPredicate
        let combinedDAIPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                daiORCompoundPredicate,
                notAppealedPredicate
            ]
        )
        
        
        // Creating the final combined predicate (OR) to return all encumbered credential objects
        let finalPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: [
            restrictionPredicate,
            combinedDAIPredicate
            ]
        )
        
        // Applying the final predicate to the fetch request
        credFetch.predicate = finalPredicates
        credFetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let encumberedCredentials = (try? container.viewContext.fetch(credFetch)) ?? []
        return encumberedCredentials
    }
    
    
    
}//: DataController

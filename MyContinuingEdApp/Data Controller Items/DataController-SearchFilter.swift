//
//  DataController-SearchFilter.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large amount of code in the DataController class, separating out similar
// functions in order to improve code organization and readability.

import CoreData
import Foundation


extension DataController {
    // MARK: - Search & Filter Methods
    
    /// This function stores whatever filter the user has selected into a filter variable, but if none is selected
    /// saves the allActivities smart filter.  A compound NSPredicate is created by this function, and within the
    /// compound predicate is the tag that the user selected (if applicable) as well as the modification date.
    /// A fetch request is created that creates the compound predicates and supplies that to the viewContext's fetch
    /// request, returning an array of any CeActivity objects having the selected tag.
    func activitiesForSelectedFilter() -> [CeActivity] {
        let filter = selectedFilter ?? .allActivities
        var predicates: [NSPredicate] = [NSPredicate]()
        
        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(format: "modifiedDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }
        
        // Adding any selected tokens to the predicates array
        if filterTokens.isNotEmpty {
            let tokenPredicate = NSPredicate(format: "ANY tags IN %@", filterTokens)
            predicates.append(tokenPredicate)
        }
        
        // Adding selected credential to the predicates array
        if let chosenCredential = filter.credential {
            let credentialPredicate = NSPredicate(format: "ANY credentials == %@", chosenCredential)
            predicates.append(credentialPredicate)
        }
        
        // Adding any selected renewal period to the predicates
        if let renewalPeriod = filter.renewalPeriod {
            let renewalPredicate = NSPredicate(format: "renewal == %@", renewalPeriod)
            predicates.append(renewalPredicate)
        }
        
        // if the user activates the filter feature, add the selected filters to the compound NSPredicate
        if filterEnabled {
            // Credential filter
            if filterCredential != "" {
                let credPredicate = NSPredicate(format: "ANY credentials IN %@", filterCredential)
                predicates.append(credPredicate)
            }
            
            // Rating filter
            if filterRating >= 0 {
                let ratingPredicate = NSPredicate(format: "evalRating = %d", filterRating)
                predicates.append(ratingPredicate)
            }
            // Expiration status filter
            if filterExpirationStatus != .all {
                // All completed activities filter
                let lookForCompleted = filterExpirationStatus == .finishedActivity
                let completedActivityPredicate = NSPredicate(format: "activityCompleted = %@", NSNumber(value: lookForCompleted))
                predicates.append(completedActivityPredicate)
                
                // Finding activities under other statuses
                let otherStatusPredicate = NSPredicate(format: "currentStatus = %@", filterExpirationStatus.rawValue)
                predicates.append(otherStatusPredicate)
                
            }
        } //: IF Filter Enabled
        
        let request = CeActivity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // For sorting the selected filter/sort items:
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        
        let allActivities = (try? container.viewContext.fetch(request)) ?? []
        return allActivities
    }
    
    
    /// Function that filters all activities from the activitiesForSelectedFilter method by a specified letter so they can
    /// be grouped alphabetically in ContentView or wherever else needed.
    /// - Parameter letter: single String character representing the letter to filter activities by
    /// - Returns: array of CeActivities that all start with the specified letter
    func activitiesBeginningWith(letter: String) -> [CeActivity] {
        guard letter.count == 1 else { return [] }
        
        let loweredLetter = letter.lowercased()
        
        let allActivities = activitiesForSelectedFilter()
        let activitiesWithLetter = allActivities.filter {
            $0.ceTitle.lowercased().hasPrefix(loweredLetter)
        }
        
        return activitiesWithLetter
    }//: activitiesBeginningWith(letter)
    
    
    
    
}//: DataController

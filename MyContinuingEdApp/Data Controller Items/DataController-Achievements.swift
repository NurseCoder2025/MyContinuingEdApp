//
//  DataController-Achievements.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large size of the DataController class, separating out functions with similar
// functionality in order to improve code organization and readability.

import CoreData
import Foundation

extension DataController {
    // MARK: - ACHIEVEMENTS Related Functions
    
    /// Using a passed in NSFetchRequest, this function will call the request on the view context
    /// , returning an integer value representing the result of the fetch request's count method
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    /// The addContactHours function is designed to add up all of the contact
    /// hours returned from a CeActivity fetch request and return that value
    /// as a double which can then be used.
    func addAwardedCE(for fetchRequest: NSFetchRequest<CeActivity>) -> Double {
        do {
            let fetchResult = try container.viewContext.fetch(fetchRequest)
            
            var totalValue: Double = 0
            let allCE: [Double] = {
                var hours: [Double] = []
                for activity in fetchResult {
                    hours.append(activity.ceAwarded)
                } //: LOOP
                
                return hours
            }() //: allHours
            
            for ce in allCE {
                totalValue += ce
            }
            
            return totalValue
            
        } catch  {
            print("Error adding awarded CE up")
            return 0
        }
        
        
    }
    
        
    // Function to determine whether an award has been earned
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
            // # of hours earned achievements
        case "CEs":
            let fetchRequest = CeActivity.fetchRequest()
            var cePredicates: [NSPredicate] = []
            // Retrieves all CeActivities where hours were awarded
            let awardedAmountPredicate = NSPredicate(format: "ceAwarded > %f", 0.0)
            let completedPredicate = NSPredicate(format: "activityCompleted == true")
            cePredicates.append(awardedAmountPredicate)
            cePredicates.append(completedPredicate)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: cePredicates)
            
            // ONLY retrieve the ceAwarded property so all values can be added
            fetchRequest.propertiesToFetch = ["ceAwarded"]
            
            let totalHours = addAwardedCE(for: fetchRequest)
            return totalHours >= Double(award.value)
            
            // # of completed CEs
        case "completed":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "activityCompleted == true")
            
            let totalCompleted = count(for: fetchRequest)
            return totalCompleted >= award.value
            
            // # tags created
        case "tags":
            let fetchRequest = Tag.fetchRequest()
            let totalTags = count(for: fetchRequest)
            return totalTags >= award.value
            
            // # activities rated as "loved"
        case "loved":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating == %d", 4)
            let totalLoved = count(for: fetchRequest)
            return totalLoved >= award.value
            
            // # activities rated as "interesting"
        case "howInteresting":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating == %d", 3)
            let totalUnliked = count(for: fetchRequest)
            return totalUnliked >= award.value
            
            // # of activity reflections completed
        case "reflections":
            let fetchRequest = ActivityReflection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completedYN == true")
            let totalReflections = count(for: fetchRequest)
            return totalReflections >= award.value
            
            // # of activity reflections where something surprising was learned
        case "surprises":
            let fetchRequest = ActivityReflection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "surpriseEntered == true")
            let totalSurprises = count(for: fetchRequest)
            return totalSurprises >= award.value
            
            // TODO: Determine why the default case is executing each time the award screen
            // shows up. This also happens each time a button is pressed.
        case "unlock":
            if purchaseStatus != PurchaseStatus.free.id {
                return true
            } else {
                return false
            }
        default:
            print("Sorry, but no award to bestow...")
            return false
        
        } //: hasEarned
    }
    
}//: DataController

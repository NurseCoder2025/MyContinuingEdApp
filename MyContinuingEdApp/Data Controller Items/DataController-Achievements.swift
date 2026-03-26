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
    }//: count(for)
    
    /// The addContactHours function is designed to add up all of the contact
    /// hours returned from a CeActivity fetch request and return that value
    /// as a double which can then be used.
    ///
    /// - Important: Updated this method to handle situations where the CEs awarded property
    /// acutally represents units instead of clock hours.  Since clock hours are needed, this method
    /// will either return the value of clockHoursAwarded (if > 0) or do a "guesstimate" conversion using
    /// the standard hours to units ratio of 10:1, which should approximate how many clock hours a user
    /// has spent in a CE activity where units were awarded.
    func addAwardedCE(for fetchRequest: NSFetchRequest<CeActivity>) -> Double {
        do {
            let fetchResult = try container.viewContext.fetch(fetchRequest)
            
            var totalValue: Double = 0
            let allCE: [Double] = {
                var hours: [Double] = []
                for activity in fetchResult {
                    switch activity.hoursOrUnits {
                    case 2:
                        if activity.clockHoursAwarded > 0 {
                            hours.append(activity.clockHoursAwarded)
                        } else {
                            let convertedHrs = Double(activity.ceAwarded * 10)
                            hours.append(convertedHrs)
                        }
                    default:
                        hours.append(activity.ceAwarded)
                    }//: SWITCH
                    
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
        
        
    }//: addAwardedCE()
    
        
    /// Method that determines whether the user has earned a specific Achievement or not.
    /// - Parameter award: Achievement object (CoreData entity) to check
    /// - Returns: True if criteria for the achievement has been met; False if not
    ///
    /// The logic for this method utilizes the criterion property for each Achievement object.  If the
    /// argument has a criterion property that is nil, then false will be returned along with a print statement
    /// indicating that no achievement was made. Each criterion has its own unique set of fetch requests that
    /// are run to determine if the achievement has been earned.
    func hasEarned(award: Achievement) -> Bool {
        // TODO: Determine why the default case is executing each time the award screen shows up. This also happens each time a button is pressed.
        switch award.awardCriteria {
        case .ces:
            // MARK: - CE HOURS
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
        case .completed:
            // MARK: - Completed CEs
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "activityCompleted == true")
            
            let totalCompleted = count(for: fetchRequest)
            
            return totalCompleted >= award.value
        case .tags:
            // MARK: - Tags created
            let fetchRequest = Tag.fetchRequest()
            let totalTags = count(for: fetchRequest)
            
            return totalTags >= award.value
        case .loved:
            // MARK: - "Loved" CEs
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating == %d", 4)
            let totalLoved = count(for: fetchRequest)
            
            return totalLoved >= award.value
        case .howInteresting:
            // MARK: - "Interesting" CEs
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating == %d", 3)
            let totalUnliked = count(for: fetchRequest)
            
            return totalUnliked >= award.value
        case .reflections:
            // MARK: - Reflections
            // # of activity reflections completed
            let fetchRequest = ReflectionResponse.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completeAnswerYN == true")
            let totalReflections = count(for: fetchRequest)
            
            return totalReflections >= award.value
        case .surprises:
            // MARK: - SURPRISES
            let fetchRequest = ActivityReflection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "surpriseEntered == true")
            let totalSurprises = count(for: fetchRequest)
            
            return totalSurprises >= award.value
        case .unlock:
            // MARK: - SUPPORTER
            if purchaseStatus != PurchaseStatus.free.id {
                return true
            } else {
                return false
            }
        case .beatExpiration:
            // MARK: - BEAT EXPIRATION
            // 15 activities completed prior to expiring
            let fetchRequest = CeActivity.fetchRequest()
            var predicates: [NSPredicate] = []
            let completedActivityPredicate = NSPredicate(format: "activityCompleted == true")
            let notExpiredPredicate = NSPredicate(format: "dateCompleted < %@", "expirationDate")
            predicates.append(completedActivityPredicate)
            predicates.append(notExpiredPredicate)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            
            let totalCompleted = count(for: fetchRequest)
            
            return totalCompleted >= Int(award.value)
        case .earlyRegistration:
            // MARK: - EARLY REGISTRATION
            let context = container.viewContext
            let ceFetch = CeActivity.fetchRequest()
            let uncompletedPred = NSPredicate(format: "activityCompleted == false")
            ceFetch.predicate = uncompletedPred
            let allUncompletedCes = (try? context.fetch(ceFetch)) ?? []
            guard allUncompletedCes.isNotEmpty else { return false }
            let liveCes = allUncompletedCes.filter { $0.isLiveActivity }
            let earlyRegisteredCes = liveCes.filter {
                let calendar = Calendar.current
                if let registeredTime = $0.registeredOn, let ceStartsAt = $0.startTime {
                    let pureRegTime = calendar.startOfDay(for: registeredTime)
                    let pureStartTime = calendar.startOfDay(for: ceStartsAt)
                    let secondsPerWeek: Double = 60 * 60 * 24 * 7
                    let secondsBetween = pureRegTime.distance(to: pureStartTime)
                    let weeksBetween = Int(secondsBetween / secondsPerWeek)
                    return weeksBetween >= 4
                } else {
                    return false
                }//: IF LET ELSE
            }//: liveCes.filter
            return earlyRegisteredCes.count >= Int(award.value)
        case .prompt:
            // MARK: - PROMPT
            let promptFetch = ReflectionPrompt.fetchRequest()
            let promptIsCustom = NSPredicate(format: "customYN == true")
            promptFetch.predicate = promptIsCustom
            
            let totalMade = count(for: promptFetch)
            return totalMade >= Int(award.value)
        case .notFound:
            NSLog(">>> The awardCriteria computed property for the award \(award.achievementName) was unable to match the criterion string with one of the enum cases.")
            NSLog(">>> The awardCriteria string was: \(award.achievementCriterion)")
            return false
        }//: SWITCH
    }//: hasEarned
    
    /// Method for checking if any new Achievements have been made and, if so, set the dateEarned property to the current
    /// time and schedule a notification to the user.
    ///
    /// Only Achievements which have a nil dateEarned property will be assessed with the hasEarned(award) method.  For those
    /// that return a true value, the scheduleAchievementNotification(award) method will be called to schedule a notification 30
    /// seconds after the current time.
    ///
    /// - Note: Call this method whenever a user might potentially earn a new Achievement, such as after completing a CE,
    /// creating a tag, completing an activity reflection, etc.  Refer to the Awards.json file for possible achievements.
    func checkForNewAchievements() {
        let context = container.viewContext
        let achievementFetch = Achievement.fetchRequest()
        achievementFetch.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        achievementFetch.predicate = NSPredicate(format: "dateEarned == nil")
        
        let possibleAchievements = (try? context.fetch(achievementFetch)) ?? []
        guard possibleAchievements.isNotEmpty else {return}
        
        
        for achievement in possibleAchievements {
            if hasEarned(award: achievement) {
                achievement.dateEarned = Date.now
                save()
                Task { @MainActor in
                    await scheduleAchievementNotification(award: achievement)
                }//: TASK
            }//: IF (hasEarned)
        }//: LOOP
        
    }//: checkForNewAchievements
    
    
    func getAllAchievements() -> [Achievement] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(fetchRequest)) ?? []
    }//: getAllAchievements()
    
}//: DataController

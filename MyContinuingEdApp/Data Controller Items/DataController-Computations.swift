//
//  DataController-Computations.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/3/25.
//

import CoreData
import Foundation


extension DataController {
    
    /// Function for calculating the number of days between the current date and the end date for a given renewal period.  This funciton is
    /// intended to be used within the CredentialNextExpirationSectionView and only take the most recent renewal period object.
    /// - Parameter renewals: array of RenewalPeriod objects (should be the renewalsSorted computed property)
    /// - Returns: a tuple with the number of days until expiration (Int) and the name of the renewal period (String)
    func calcTimeUntilNextExpiration(renewals: [RenewalPeriod]) -> (days:Int, name:String) {
        // Return a -1 if no renewal periods currently exist (and nothing was passed in)
        guard renewals.isNotEmpty else {return (-1, "")}
        
        // Get today's date
        let todaysDate: Date = Date.now
        
        // Find the renewal period that today's date falls within
        let currentRenewalArray = renewals.filter {
            $0.renewalPeriodStart <= todaysDate && $0.renewalPeriodEnd >= todaysDate
        }
        
        // Convert the array to a single object (if it exists)
        guard let currentRenewal = currentRenewalArray.first else {return (-1, "")}
        
        // Calculate the number of days between today's date and the end date for the current renewal period
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: todaysDate, to: currentRenewal.renewalPeriodEnd).day ?? -1
        
        return (daysUntilExpiration, currentRenewal.renewalPeriodName)
        
     }//: FUNC
    
    
    /// Function that returns a tuple with the number of days remaining in a given renewal period.
    /// Designed to be called from anywhere within the app where needed as it evaluates only
    /// a single renewal period.
    /// - Parameter renewal: RenewalPeriod object with a valid ending date (not nil)
    /// - Returns: Number of days til expiration + name of RenewalPeriod as a tuple
    func calculateRemainingTimeUntilExpiration(renewal: RenewalPeriod) -> (days: Int, name: String){
        guard renewal.periodEnd != nil else {return (-1, "")}
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expirationDate = calendar.startOfDay(for: renewal.renewalPeriodEnd)
        
        let daysTilRenewal = calendar.dateComponents([.day], from: today, to: expirationDate).day ?? -1
        
        return (daysTilRenewal, renewal.renewalPeriodName)
        
    }//: calculateRemainingTimeUntilExpiration(renewal)
    
    
    // MARK: - CE HOUR COMPLETION
    /// This method calculates the total number of CE hours (or units) that remain needed for a given renewal period.  Only CeActivities
    /// which meet the inclusion criteria of being marked as completed, fall under the same renwal period, and have a value > 0 for the cesAwarded
    /// property, will be included in the calculation.
    /// - Parameter renewal: RenewalPeriod object for which remaining CEs are due for (can be a previous or current period)
    /// - Returns: Tuple with 3 elements: the number of CEs still needed (Double), if the renewal period is the current period (Bool), and
    ///     whether the amount being returned is in hours or units.
    func calculateRemainingTotalCEsFor(renewal: RenewalPeriod) -> (ces: Double, current: Bool, unit: Int16) {
        guard let renewalCred = renewal.credential, renewalCred.renewalCEsRequired > 0 else { return (0.0, false, 1)}
        var requiredCEs: Double = 0.0
        var requirementUnit: Int16 = 1
        var unitsPerHour: Double = 10.0
       
        requiredCEs = renewalCred.renewalCEsRequired
        requirementUnit = renewalCred.measurementDefault
        unitsPerHour = renewalCred.defaultCesPerUnit
        // Fetch all relevant CeActivities for RenewalPeriod
        var activityPredicates: [NSPredicate] = []
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        
        let activityMatchRenewal = NSPredicate(format: "renewal == %@", renewal)
        let onlyCompletedActivity = NSPredicate(format: "activityCompleted == true")
        let hoursAwardedHasValue = NSPredicate(format: "ceAwarded > %f", 0.0)
            activityPredicates.append(activityMatchRenewal)
            activityPredicates.append(onlyCompletedActivity)
            activityPredicates.append(hoursAwardedHasValue)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let renewalActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard renewalActivities.isNotEmpty else { return (0.0, false, 1)}
        
        // Calculating the number of hours earned
        var totalCEAwarded: Double = 0.0
        for activity in renewalActivities {
            // Need to make sure that the CE units entered in the Credential
            // renewalCEsRequired property is the same as what was entered for the CeActivity,
            // and if not, convert accordingly.
            if activity.hoursOrUnits == requirementUnit {
                totalCEAwarded += activity.ceAwarded
            } else if requirementUnit == 1 && activity.hoursOrUnits == 2 {
                let cesInHours = activity.ceAwarded * unitsPerHour
                totalCEAwarded += cesInHours
            } else if requirementUnit == 2 && activity.hoursOrUnits == 1 {
                let hoursInCES = activity.ceAwarded / unitsPerHour
                totalCEAwarded += hoursInCES
            }
            
        }
        
        let remainingCEs: Double = requiredCEs - totalCEAwarded
        
        // Determining if renewal period is current
        let allCurrentRenewals = getCurrentRenewalPeriods()
        let isCurrent: Bool = allCurrentRenewals.contains(where: { $0.periodID == renewal.periodID })
        
        return (remainingCEs, isCurrent, requirementUnit)
        
    }//: calculateRemainingCEHoursFor(renewal)
    
    
    /// This method evaluates all SpecialCategory objects for a given Credential, and for a given RenewalPeriod for that Credential, this
    /// method returns how many more hours or units the user needs to complete for each SpecialCategory object that is assigned
    /// to the Credential.
    ///
    /// - Parameter renewal: RenewalPeriod object representing the renewal period to be evaluated
    /// - Returns: a dictionary composed of a String key and a Double value, representing each SpecialCategory for a given Credential,
    ///     with the name of the SpecialCategory serving as the String key and the computed hours/units still needed as the Double value
    func calculateRemainingSpecialCECatHoursFor(renewal: RenewalPeriod) -> [String : Double] {
        guard let renewalCred = renewal.credential else { return [:]}
        
        // Defining the dictionary to hold values for each special category assigned
        var remainingSpecialCatHours: [String: Double] = [:]
        
        // Fetching activities to go through and add up hours/units
        var activityPredicates: [NSPredicate] = []
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        
        let activityMatchRenewal = NSPredicate(format: "renewal == %@", renewal)
        let onlyCompletedActivity = NSPredicate(format: "activityCompleted == true")
        let hoursAwardedHasValue = NSPredicate(format: "ceAwarded > %f", 0.0)
        let assignedSpecialCat = NSPredicate(format: "specialCat != nil")
            activityPredicates.append(activityMatchRenewal)
            activityPredicates.append(onlyCompletedActivity)
            activityPredicates.append(hoursAwardedHasValue)
            activityPredicates.append(assignedSpecialCat)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let renewalActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard renewalActivities.isNotEmpty else { return remainingSpecialCatHours }
        
        // Iterating through all assigned Special Categories for the renewal period's Credential
        if let assignedSpecialCats = renewalCred.specialCats as? Set<SpecialCategory> {
            for specialCat in assignedSpecialCats {
                let catKey: String = specialCat.specialName
                let requiredCatHours: Double = specialCat.requiredHours
                guard requiredCatHours > 0.0 else { continue }
                var catTotal: Double = 0.0
                for activity in renewalActivities {
                    // Need to make sure that the CE units entered in the SpecialCategory
                    // requiredHours property is the same as what was entered for the CeActivity,
                    // and if not, convert accordingly.
                    if activity.specialCat == specialCat {
                        if specialCat.measurementDefault == activity.hoursOrUnits {
                            catTotal += activity.ceAwarded
                        } else if specialCat.measurementDefault == 1 && activity.hoursOrUnits == 2 {
                            let unitsToHours = activity.ceAwarded * renewalCred.defaultCesPerUnit
                            catTotal += unitsToHours
                        } else if specialCat.measurementDefault == 2 && activity.hoursOrUnits == 1 {
                            let hoursToUnits = activity.ceAwarded / renewalCred.defaultCesPerUnit
                            catTotal += hoursToUnits
                        }//: IF ELSE IF
                    }//: IF
                }//: LOOP (activity)
                let remainingCEs: Double = requiredCatHours - catTotal
                remainingSpecialCatHours[catKey] = remainingCEs
            }//: LOOP (special cat)
        }//: IF LET
        
        return remainingSpecialCatHours
    }//: calculateRemainingSpecialCECatHoursFor(renewal)
    
    /// Method that retrieves all CeActivities meeting the four inclusion criteria, groups them by year and month, and then for each month
    /// calculates the total number of CE clock hours earned for that month.
    /// - Returns: Dictionary with the Year-Month Date key and a Double value representing the total # of CE clock hours awarded
    func calculateCEsEarnedByMonth() -> [Date : Double] {
        // Fetch all CeActivities that meet the following criteria:
        // 1. Marked as completed
        // 2. Have a ceAwarded value > 0
        // 3. Has a date entered in dateCompleted
        // 4. dateCompleted is either before or on today's date
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "dateCompleted", ascending: true)]
        
        var activityPredicates: [NSPredicate] = []
        let completedPredicate = NSPredicate(format: "activityCompleted == true")
        let awardedPredicate = NSPredicate(format: "ceAwarded > %f", 0.0)
        let validDatePredicate = NSPredicate(format: "dateCompleted != nil")
        let completionPredateTodayPredicate = NSPredicate(format: "dateCompleted <= %@", Date.now as NSDate)
            activityPredicates.append(completedPredicate)
            activityPredicates.append(awardedPredicate)
            activityPredicates.append(validDatePredicate)
            activityPredicates.append(completionPredateTodayPredicate)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let completedActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard completedActivities.isNotEmpty else { return [:] }
        
        let calendar = Calendar.current
        let distantPastDate = Date.distantPast

        // Group activities by year, then month
        var yearMonthGroups: [Date] = []
        var groupedByYearMonth: [Date : [CeActivity]] = [:]
        // Purpose of this loop is to create a Month-Year date for each activity and then add all unique
        // Month-Year dates to the yearMonthGroups array
        for activity in completedActivities {
            if let completionDate = activity.dateCompleted {
                let normalizedDate = calendar.startOfDay(for: completionDate)
                let yearMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: normalizedDate)) ?? distantPastDate
                
                guard yearMonthDate != distantPastDate else { continue }
                
                if yearMonthGroups.doesNOTContain(yearMonthDate) {
                    yearMonthGroups.append(yearMonthDate)
                }
            }//: IF LET
        }//: LOOP
        
        // Purpose of this loop is to run through each Month-Year date in the groupedByYearMonth array and
        // add any CeActvities to the corresponding date key's CeActivity array if the activity was
        // completed in the matching month and year.
        for date in yearMonthGroups {
            for activity in completedActivities {
                let normalizedDate = calendar.startOfDay(for: activity.dateCompleted ?? distantPastDate)
                let yearMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: normalizedDate)) ?? distantPastDate
                
                guard yearMonthDate != distantPastDate, yearMonthDate == date else { continue }
                
                groupedByYearMonth[date, default: []].append(activity)
            }//: LOOP
        }//: LOOP
        
        // For adding up all ces awarded in each month
        var ceTotalResults: [Date : Double] = [:]
        for key in groupedByYearMonth.keys {
            var ceTotal: Double = 0.0
            for activity in groupedByYearMonth[key] ?? [] {
                let activityCEClockHours = convertCesAwardedToHoursFor(activity: activity)
                ceTotal += activityCEClockHours
            }//: LOOP
            ceTotalResults[key] = ceTotal
        }//: LOOP
        
      
        return ceTotalResults
        
    }//: calculateCEsEarnedByMonth
    
    /// This method is designed to covert the amount of CE awarded for a given activity into clock hours, if needed, so that
    /// computation for CEs earned can be reported in one value unit (clock hours).
    /// - Parameter activity: CeActivity for which CE clock hours need to be calculated
    /// - Returns: converted CEs as clock hours as its value as a Double
    ///
    /// A key assumption made in this function is that if a user completes an activity that awards CE in units verus clock
    /// hours then that activity is specific to a particular credential and the activity will only be assigned to that credential
    /// or, if any others, the remaining use clock hours as the reporting unit. Since most users only have one credential, with a smaller
    /// number having two, then this assumption should be safe for the majority of users.
    private func convertCesAwardedToHoursFor(activity: CeActivity) -> Double {
        guard activity.activityCompleted, activity.ceAwarded > 0 else { return 0.0 }
        let activityUnit = activity.hoursOrUnits
        
        if activityUnit == 1 {
            return activity.ceAwarded
        } else {
            // ** Assumption **
            // For the purpose of simplicity, this alogrythim will assume that if a user
            // enters the amount of CE awarded in terms of units, then the activity will only be
            // assigned to a specific credential which has its own units to hours conversion
            // ratio. If no credentials are assigned, then the standard conversion ratio
            // of 10 hours per unit will be used for calculating the number of clock hours.
            if let allAssignedCreds = activity.credentials as? Set<Credential> {
                let credRequiringUnits: Credential? = allAssignedCreds.first(where: { $0.measurementDefault == 2})
                
                if let credWithUnitRequirement = credRequiringUnits {
                    guard credWithUnitRequirement.defaultCesPerUnit > 0 else {
                        return activity.ceAwarded * 10
                    }
                    return activity.ceAwarded * Double(credWithUnitRequirement.defaultCesPerUnit)
                }
                
            }//: IF LET
            
            // Returning the ceAwarded amount multiplied by the standard units to clock hours ratio
            // of 10 hours per unit if either no Credentials have been assigned to the activity OR
            // there aren't any Credentials assigned to the activity that require CEs to be
            // reported in terms of units
            return activity.ceAwarded * 10.0
        }//: IF ELSE
        
    }//: convertCesAwardedFor(activity)
    
    
    
    
    
}//: DATA CONTROLLER

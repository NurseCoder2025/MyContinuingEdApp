//
//  DataController-Computations.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/3/25.
//

import CoreData
import Foundation


extension DataController {
    
    // MARK: - Time Interval Calculations
    
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
    
    /// Method that computes a date that is so many months ahead of the passed-in renewal period's end date. Mainly intended for use in scheduling
    /// notifications, but can be used elsewhere.
    /// - Parameters:
    ///   - months: Int value which should be a negative value, representing how many months ahead the returned date should be
    ///   - renewal: RenewalPeriod object for which a notification date needs to be calculated
    /// - Returns: Optional Date value representing the date that is however many months ahead of the renewal end date
    ///
    /// This function returns an OPTIONAL Date value becuase either the passed-in renewal period object does not have a value for periodEnd or
    /// the specified date calculation could not be determined by the .date(byAdding) method.  In the event a positive Int is used as the argument
    /// for months, the method will automatically convert it to a negative value so that the right date can be returned.
    func getCustomMonthsLeftInRenewalDate(months: Int, renewal: RenewalPeriod) -> Date? {
        guard renewal.periodEnd != nil else {return nil}
        var monthsPrior: Int = 0
        
        // Ensuring that if the months argument is positive, it is turned to a negative in order to correctly
        // return the date that is that many months AHEAD of the renewal end date.
        if months > 0 {
            monthsPrior = (0 - months)
        } else {
            monthsPrior = months
        }
        
        let calendar = Calendar.current
        let pureEndDate = calendar.startOfDay(for: renewal.renewalPeriodEnd)
        
        let earlyNotificationDate = calendar.date(byAdding: .month, value: monthsPrior, to: pureEndDate)
        
        return earlyNotificationDate
    }//: getCustomMonthsLeftInRenewalDate()
    
    
    // MARK: - CE PROGRESS METHODS
    // Since CEs can be measured in either clock hours or units, the approach being taken
    // in this app is to first convert everything into clock hours (required and earned CEs).
    // Then, after the percentage is calculated, convert the remaining amount of CE clock hours
    // into units IF indicated by a Credential's measurementDefault (Int16) property of 1 for
    // clock hours (default) or 2 (units).
    
    /// Method that calculates the total number of continuing education clock HOURS that are required for a given
    /// RenewalPeriod object.
    /// - Parameter renewal: RenewalPeriod object for which the total # of CE hours is being sought
    /// - Returns: a Double representing the total number of clock HOURS required for a credential's renewal
    ///
    /// If the user has a Credential where continuing education contact hours are measured in units versus hours
    /// (2 vs 1 property value for the Credential's measurementDefault property), then the conversion will need to be handled by
    /// a separate method before returning the final result to the user.
    ///
    /// Additionally, this method ignores any additional CEs that may be required due to a Credential being lapsed and needing
    /// reinstated.  A separate method is available to handle this particular scenario as CEs earned for reinstating a credential
    /// are NOT applied towards the regular renewal process.
        func calculateTotalRequiredCEsFor(renewal: RenewalPeriod) -> Double {
        guard let renewalCred = renewal.credential else {return 0}
        
        let credDefault = renewalCred.measurementDefault
        var requiredClockHours: Double = 0.0
        
        // If the Credential's default CE measurement is units, convert
        // the required amount to clock hours; otherwise, just use whatever value is in
        // the Credential's renewalCEsRequired property
        if credDefault == 2 {
            requiredClockHours = renewalCred.renewalCEsRequired * renewalCred.defaultCesPerUnit
            
        } else  {
            requiredClockHours = renewalCred.renewalCEsRequired
        }
        
        return requiredClockHours
    }//: calculateTotalRequiredCEsFor()
    
    /// Method that indicates whether any given RenewalPeriod object is current, meaning that the current date falls within
    /// the renewal's starting and ending dates.
    /// - Parameter renewal: RenewalPeriod object for determining whether it is current or not
    /// - Returns: true if current date is within renewal's starting and ending dates; false if not
    ///
    /// This method calls the getCurrentRenewalPeriods() method from the DataController-Notifications file, which collects all
    /// RenewalPeriod objects that meet the date inclusion criteria and returns them as an array.
    /// If the RenewalPeriod passed in is found in that array, then this method will return true.
    func renewalPeriodIsCurrentYN(_ renewal: RenewalPeriod) -> Bool {
        let allCurrentRenewals = getCurrentRenewalPeriods()
        let isCurrent: Bool = allCurrentRenewals.contains(where: { $0.periodID == renewal.periodID })
        return isCurrent
    }//: renewalPeriodIsCurrentYN()
    
    /// Method that computes how many CEs in terms of clock hours has been earned for a given renewal period.
    /// - Parameter renewal: RenewalPeriod of interest
    /// - Returns: CE clock hours as a Double
    func calculateRenewalPeriodCEsEarned(renewal: RenewalPeriod) -> Double {
        guard renewal.credential != nil else {return 0}
        
        return (calculateTotalRequiredCEsFor(renewal: renewal) - calculateRemainingTotalCEsFor(renewal: renewal))
        
    }//: calculateRenewalPeriodCEsEarned
    
    /// This method calculates the total number of CE clock hours that remain needed for a given renewal period.  Only CeActivities
    /// which meet the inclusion criteria of being marked as completed, fall under the same renwal period, and have a value > 0 for the cesAwarded
    /// property, will be included in the calculation.
    /// - Parameter renewal: RenewalPeriod object for which remaining CEs are due for (can be a previous or current period)
    /// - Returns: CE clock HOURS as a Double
    ///
    /// If the user's credential uses units as the CE measurement, then the returned value will need to be converted from clock hours to units separately.
    func calculateRemainingTotalCEsFor(renewal: RenewalPeriod) -> Double {
        guard let renewalCred = renewal.credential, renewalCred.renewalCEsRequired > 0 else { return 0.0 }
        // shortcut variables
        var requiredCEs: Double = 0.0
        var unitsPerHour: Double = 10.0
       
        requiredCEs = calculateTotalRequiredCEsFor(renewal: renewal)
        if renewalCred.defaultCesPerUnit <= 0 {
            unitsPerHour = 10.0
        } else {
            unitsPerHour = renewalCred.defaultCesPerUnit
        }
        
        // MARK: Fetch all relevant CeActivities for RenewalPeriod
        var activityPredicates: [NSPredicate] = []
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        
        let activityMatchRenewal = NSPredicate(format: "renewals CONTAINS %@", renewal)
        let onlyCompletedActivity = NSPredicate(format: "activityCompleted == true")
        let hoursAwardedHasValue = NSPredicate(format: "ceAwarded > %f", 0.0)
            activityPredicates.append(activityMatchRenewal)
            activityPredicates.append(onlyCompletedActivity)
            activityPredicates.append(hoursAwardedHasValue)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let renewalActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard renewalActivities.isNotEmpty else { return 0.0 }
        
        // MARK: Calculating the number of hours earned
        var totalCEAwarded: Double = 0.0
        for activity in renewalActivities {
            // Since this method returns CE remaining in terms of clock hours, need to convert
            // any activities where CE was awarded in units to clock hours
            if activity.hoursOrUnits == 2 {
                let convertedCE = activity.ceAwarded * unitsPerHour
                totalCEAwarded += convertedCE
            } else {
                totalCEAwarded += activity.ceAwarded
            }
        }//: LOOP
        
        let remainingCEs: Double = requiredCEs - totalCEAwarded
        
        return remainingCEs
        
    }//: calculateRemainingCEHoursFor(renewal)
    
    /// Method that converts CE clock hours into units for a given RenewalPeriod.
    /// - Parameters:
    ///   - hours: Number of clock hours to be converted (Double)
    ///   - renewal: RenewalPeriod object for which the hours are being converted for
    /// - Returns: Number of CE units as a Double, defined by the defaultCesPerUnit property for the Renewal's
    /// Credential
    ///
    /// If the defaultCesPerUnit property happens to be 0 or anything less, then an assumed standard value of 10 is
    /// used to convert the hours to units.
    func convertHoursToUnits(_ hours: Double, for renewal: RenewalPeriod) -> Double {
        guard let renewalCred = renewal.credential else { return 0.0 }
        let conversionRate: Double = renewalCred.defaultCesPerUnit
        if conversionRate <= 0 {
            return hours / 10.0
        } else {
            return hours / conversionRate
        }
    }//: convertHoursToUnits()
    
    
    // MARK: - Special CAT Hours

    /// This method evaluates all SpecialCategory objects for a given Credential, and for a given RenewalPeriod for that Credential, this
    /// method returns how many  clock hours were earned for each SpecialCategory object that is assigned
    /// to the Credential.
    ///
    /// - Parameter renewal: RenewalPeriod object representing the renewal period to be evaluated
    /// - Returns: a dictionary composed of a SpecialCat object key and a Double value
    ///     as the computed clock hours earned for the given renewal period
    func calculateCeEarnedForSpecialCatsIn(renewal: RenewalPeriod) -> [SpecialCategory : Double] {
        guard let renewalCred = renewal.credential, renewalCred.allSpecialCats.count > 0 else { return [:]}
        
        // Defining the dictionary to hold values for each special category assigned
        var earnedSpecialCatHours: [SpecialCategory: Double] = [:]
        
        // Fetching activities to go through and add up hours/units that have a special CE cat assigned
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        
        // ** Predicates **
        var activityPredicates: [NSPredicate] = []
        let activityMatchRenewal = NSPredicate(format: "renewals CONTAINS %@", renewal)
        let onlyCompletedActivity = NSPredicate(format: "activityCompleted == true")
        let hoursAwardedHasValue = NSPredicate(format: "ceAwarded > %f", 0.0)
        let assignedSpecialCat = NSPredicate(format: "specialCat != nil")
            activityPredicates.append(activityMatchRenewal)
            activityPredicates.append(onlyCompletedActivity)
            activityPredicates.append(hoursAwardedHasValue)
            activityPredicates.append(assignedSpecialCat)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        // Running the fetch request ------------------------------------------------
        let renewalActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard renewalActivities.isNotEmpty else { return earnedSpecialCatHours }
        
        // Iterating through all assigned Special Categories for the renewal period's Credential
        for specialCat in renewalCred.allSpecialCats {
                let requiredCatHours: Double = specialCat.requiredHours
                // Skip the current specialCat if the # of required hours is 0.0 or less
                guard requiredCatHours > 0.0 else { continue }
            
                var catTotal: Double = 0.0
                for activity in renewalActivities {
                    // Convert any CEs in units to hours for simplicity
                    // Skip any activities that are not assigned to the current specialCat
                    if activity.specialCat == specialCat {
                        if activity.hoursOrUnits == 2 {
                            let convertedCE = activity.ceAwarded * renewalCred.defaultCesPerUnit
                            catTotal += convertedCE
                        } else {
                            catTotal += activity.ceAwarded
                        }
                    }//: IF
                }//: LOOP (renewalActivities)
                earnedSpecialCatHours[specialCat] = catTotal
            }//: LOOP (special cat)
        return earnedSpecialCatHours
    }//: calculateCeEarnedForSpecialCatsIn(renewal)
    
    /// Method that loops through all SpecialCategory objects assigned to a Credential for a specific RenewalPeriod and
    /// calculates the total number of CE clock hours that still need to be earned for that renewal period.
    /// - Parameter renewal: RenewalPeriod of interest
    /// - Returns: Dictionary consisting of a SpecialCategory object as the key and the number of clock hours still needed as
    /// a Double
    ///
    /// Like the other CE calculating methods, will need to convert the resulting numbers to units with the convertHoursToUnits
    /// method if the Credential in question uses units instead of clock hours for measuring CE.
    func calculateCeRemainingForSpecialCatsIn(renewal: RenewalPeriod) -> [SpecialCategory: Double] {
        let specialCatsEarned = calculateCeEarnedForSpecialCatsIn(renewal: renewal)
        guard specialCatsEarned.count > 0 else { return [:] }
        
        var specialCatsRemaining: [SpecialCategory: Double] = [:]
        for (specialCat, ceEarned) in specialCatsEarned {
            let remaining = specialCat.requiredHours - ceEarned
            specialCatsRemaining[specialCat] = remaining
        }//: LOOP
        return specialCatsRemaining
    }//: calculateCeRemainingForSpecialCatsIn(renewal)
    
    
    // MARK: - CE CHART METHODS
    
    /// Method that retrieves all CeActivities meeting the four inclusion criteria, groups them by year and month, and then for each month
    /// calculates the total number of CE clock hours earned for that month.
    /// - Returns: Dictionary with the Year-Month Date key and a Double value representing the total # of CE clock hours awarded
    ///
    /// The primary reason for returning only clock hours as the value is for simplicity in showing the user how many CEs they have earned,
    /// no matter how many credentials they have and are tracking CEs for.  If a user were to have a credential that measured CEs in hours but
    /// had another that went by units, then converting the units to hours allows the chart to display all CEs earned for each credential as a total.
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
        
       let groupedByYearMonth = groupCeActivitiesByMonthYear(activities: completedActivities)
        
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
    
    func calculateMoneySpentByMonth() -> [Date: Double] {
        // Fetch all CeActivities that meet the following criteria:
        // 1. Marked as completed
        // 2. Has a cost > 0.00
        // 3. Has a date entered in dateCompleted
        // 4. dateCompleted is either before or on today's date
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "dateCompleted", ascending: true)]
        
        var activityPredicates: [NSPredicate] = []
        let completedPredicate = NSPredicate(format: "activityCompleted == true")
        let paidPredicate = NSPredicate(format: "cost > %f", 0.0)
        let validDatePredicate = NSPredicate(format: "dateCompleted != nil")
        let completionPredateTodayPredicate = NSPredicate(format: "dateCompleted <= %@", Date.now as NSDate)
            activityPredicates.append(completedPredicate)
            activityPredicates.append(paidPredicate)
            activityPredicates.append(validDatePredicate)
            activityPredicates.append(completionPredateTodayPredicate)
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let completedActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        guard completedActivities.isNotEmpty else { return [:] }
        
        let groupedByYearMonth = groupCeActivitiesByMonthYear(activities: completedActivities)
        
        // Adding up the total amount of money spent per month on CEs
        var moneySpent: [Date : Double] = [:]
        for key in groupedByYearMonth.keys {
            var total = 0.0
            for activity in groupedByYearMonth[key] ?? [] {
                total += activity.cost
            }//: LOOP
           moneySpent[key] = total
        }//: LOOP (key in)
        
        return moneySpent
    }//: calculateMoneySpentByMonth
    
    /// Private method for taking an array of CeActivities (via the use of predicates and sorting or not) and then grouping them by month and
    /// year, creating a standardized date (month-01-year) value that will be used as the key in the returned dictionary.
    /// - Parameter activities: Array of CeActivity objects that are to be grouped by month and year
    /// - Returns: Dictionary with a month-year date key and array of CeActivities as the value 
    private func groupCeActivitiesByMonthYear(activities: [CeActivity]) -> [Date: [CeActivity]] {
        let calendar = Calendar.current
        let distantPastDate = Date.distantPast

        // Group activities by year, then month
        var yearMonthGroups: [Date] = []
        var groupedByYearMonth: [Date : [CeActivity]] = [:]
        // Purpose of this loop is to create a Month-Year date for each activity and then add all unique
        // Month-Year dates to the yearMonthGroups array
        for activity in activities {
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
            for activity in activities {
                let normalizedDate = calendar.startOfDay(for: activity.dateCompleted ?? distantPastDate)
                let yearMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: normalizedDate)) ?? distantPastDate
                
                guard yearMonthDate != distantPastDate, yearMonthDate == date else { continue }
                
                groupedByYearMonth[date, default: []].append(activity)
            }//: LOOP
        }//: LOOP
        
        return groupedByYearMonth
    }//: groupCeActivitiesByMonthYear(activities)
    
}//: DATA CONTROLLER

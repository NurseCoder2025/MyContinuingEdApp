//
//  DataController-Reinstatement.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/9/26.
//

import Foundation

// All of the items in this DataController extension are related to the ReinstatementInfo
// and ReinstatementSpecialCat objects.

extension DataController {
    // MARK: - REINSTATEMENT Hours
    
    /// Method for calculating the total number of CEs (in clock hours) required for credential reinstatement as well as
    /// the total number that have been earned towards that total currently.
    /// - Parameter renewal: RenewalPeriod during which credential reinstatement is being done
    /// - Returns: Tuple consisting of both the total required CEs and how many have been earned (both Doubles)
    ///
    /// You can access the returned tuple values with the following names: required & earned.  If a Credential measures
    /// CEs in terms of units vs hours, this method will convert the number of required reinstatement CEs to clock
    /// hours.  For the calculation of earned CEs from completed activities, the getCeClockHoursEarned(for) method
    /// is called within the method.
    func calculateCEsForReinstatement(renewal: RenewalPeriod) -> (required:Double, earned:Double) {
        guard let reinstatementObj = renewal.reinstatement, let renewalCred = renewal.credential else { return (0.0, 0.0) }
        let ceType = renewalCred.measurementDefault
        var requiredCEs: Double = 0.0
        
        // Converting the reinstatement CE amount to clock hours if the Credential measures
        // CES in units
        if ceType == 2 {
            requiredCEs = reinstatementObj.totalExtraCEs * renewalCred.defaultCesPerUnit
        } else {
            requiredCEs = reinstatementObj.totalExtraCEs
        }
        
        // Adding up the number of CEs earned from completed activities
        var earnedTotal: Double = 0.0
        let completedActivities = renewal.completedRenewalActivities
        for activity in completedActivities {
            if activity.forReinstatementYN {
                earnedTotal += activity.getCeClockHoursEarned(for: renewalCred)
            }
        }//: LOOP
        
        return (requiredCEs, earnedTotal)
    }//: calculateCEsForReinstatement()
    
    // MARK: - Reinstatement Special Cat Requirements
    /// Method for determining if the user has met all credential-specific CE requirements for reinstating a specific
    /// credential, if applicable.
    /// - Parameter renewal: RenewalPeriod during which reinstatment is being done
    /// - Returns: True if either the user has completed the required number of CEs for each required CE category,
    /// if no reinstatement is being done for the passed in renewal period, or if no CE categories are required.  False if
    /// otherwise.
    ///
    /// This method does not return a list of which CE categories have not been met yet, but only that they
    /// either have all been met/none are required,  or CEs are needed for at least one more category.
    func checkIfSpecialCatHoursMetForReinstatement(renewal: RenewalPeriod) -> Bool {
        let specialCatLists = getReinstatementSpecialCatsLists(renewal: renewal)
        guard specialCatLists.isNotEmpty, specialCatLists.count == 2 else {return true}
        
        // Assigning each array from the getReinstatementSpecialCatsLists method to a separate variable
        let requiredHours: [ReinstatementSpecialCat: Double] = specialCatLists[0]
        let earnedHours: [ReinstatementSpecialCat: Double] = specialCatLists[1]
    
        // Comparing the earned hours with required hours for each RSC
        for (cat, required) in requiredHours {
            if let earned = earnedHours[cat], earned < required {
                return false
            }//: IF LET
        }//: LOOP
        
        return true
    }//: checkIfSpecialCatHoursMetForReinstatement(renewal)
    
    /// Method for obtaining a list (dictionary) of all credential-specific CE requirements that have not yet been met along with how many
    /// clock hours are still required for a given renewal period during which a lapsed credential is being reinstated.
    /// - Parameter renewal: RenewalPeriod during which a lapsed credential is being reinstated
    /// - Returns: Dictionary of all ReinstatementSpecialCats whose cesRequired amount has not been met yet along with the hours
    /// remaining as a Double.  If the dictionary is returned empty, then either all requirements have been met/none were in effect or there
    /// was an issue with the creation of the two dictionaries in getReinstatementSpecialCatsList.
    ///
    /// Method calls the internal function getReinstatementSpecialCatLists for fetching objects and creating the two dictionaries that are
    /// compared to determine any difference in hours between what's required and earned.  All results are in clock hours, so if the
    /// credential being reinstated uses units instead, then conversion to units will be required later.
    func getOutstandingSpecialCatsForReinstatement(renewal: RenewalPeriod) -> [ReinstatementSpecialCat: Double] {
        // First, check to see if any credential-specific CE requirements remain outstanding or not
       guard checkIfSpecialCatHoursMetForReinstatement(renewal: renewal) else {return [:]}
        
        // Next, get lists of total hours required and those earned for each CE requirement
       let specialCatLists = getReinstatementSpecialCatsLists(renewal: renewal)
       guard specialCatLists.isNotEmpty, specialCatLists.count == 2 else {return [:]}
        
        let requiredHours: [ReinstatementSpecialCat: Double] = specialCatLists[0]
        let earnedHours: [ReinstatementSpecialCat: Double] = specialCatLists[1]
        
        var outstandingHours: [ReinstatementSpecialCat: Double] = [:]
        
        for (cat, required) in requiredHours {
            if let earned = earnedHours[cat] {
                let remainingHours = required - earned
                if remainingHours > 0 {
                    outstandingHours[cat] = remainingHours
                }
            }//: IF LET
        }//: LOOP
        
        return outstandingHours
        
    }//: getOutstandingSpecialCAtsForReinstatement()
    
    /// Internal method for retrieving two separate dictionaries containing all ReinstatmentSpecialCat objects assigned to a given RenewalPeriod
    /// during which a credential is being reinstated.  The first dictionary contains each RSC along with the total required hours for it while the
    /// second dictionary contains each RSC and how many hours have been earned thus far.
    /// - Parameter renewal: RenewalPeriod during which a credential is being renewed
    /// - Returns: Array of dictionaries (but always 2) - one containing required hours and the other earned hours
    ///
    /// This method was written to be used inside of other methods related to credential-specific CE requirements particular to a credential
    /// reinstatement that the user may setup.  The first dictionary in the array is always the one with the total hours required while the second
    /// contains the number of hours earned.  All CEs are in terms of clock hours, so conversion to units may be needed later if the credential
    /// goes by that instead of clock hours.
    private func getReinstatementSpecialCatsLists(renewal: RenewalPeriod) -> [[ReinstatementSpecialCat:Double]] {
        guard let renewRein = renewal.reinstatement, renewRein.requiredSpecialCatHours.isNotEmpty, let renewCred = renewal.credential else { return [] }
        
        // Fetch all activities for the renewal period which have a special category
        // assigned to them
        let relevantActivities = renewal.completedActivitiesWithSpecialCats
        
        var requiredCatHours: Double = 0.0
        let requiredCats = Set(renewRein.requiredSpecialCatHours)
        var catRequiredHours = [ReinstatementSpecialCat: Double]()
        var catEarnedHours = [ReinstatementSpecialCat: Double]()
        
        // Filling the two dictionaries with required hours and earned hours
        // for each ReinstatementSpecialCat that has a SpecialCategory assigned
        // to it.
        for cat in requiredCats {
            if let assignedCat = cat.specialCat {
                // Convert cesRequired to clock hours if applicable
                if renewCred.measurementDefault == 2 {
                    requiredCatHours = cat.cesRequired * renewCred.defaultCesPerUnit
                } else {
                    requiredCatHours = cat.cesRequired
                }
                
                catRequiredHours[cat] = requiredCatHours
                var ceEarned: Double = 0.0
                for activity in relevantActivities {
                    if activity.specialCat == assignedCat, let renewCred = renewal.credential {
                        ceEarned += activity.getCeClockHoursEarned(for: renewCred)
                    }//: IF
                }//: LOOP (activity in relevantActivities)
                catEarnedHours[cat] = ceEarned
            } else {
                continue
            }//: IF LET
        }//: LOOP (cat in requiredCats)
        
        return [catRequiredHours, catEarnedHours]
    }//: getReinstatementSpecialCAtLists
    
}//: EXTENSION

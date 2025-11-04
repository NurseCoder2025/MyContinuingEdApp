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
    
    
    
}//: DATA CONTROLLER

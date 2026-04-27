//
//  Date+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/1/26.
//

import Foundation


extension Date {
     // MARK: - CONSTANTS
    // Adding a property that will provide a reasonable future expiration date for new CE activities
    /// Computed constant date that is set for two years from the current date and time
    static let futureExpiration: Date = Date.now.addingTimeInterval(86400 * 730)
    
    // Property for providing a more reasonable future completion date for new CE activities
    /// Computed constant date that is set for 6 months from the current date and time
    static let futureCompletion: Date = Date.now.addingTimeInterval(86400 * 180)
    
    // Property for providing a reasonable renewal period start date
    /// Computed constant date that is set for 6 months prior to the current date and time
    static let renewalStartDate: Date = Date.now.addingTimeInterval(86400 * -180)
    
    // Property for providing a reasonable renewal period end date
    /// Computed constant date that is set for three years after the current date and time
    static let renewalEndDate: Date = Date.now.addingTimeInterval(86400 * 1095)
    
    // Property for providing a reasonable late fee start date for a given renewal period
    /// Computed constant date that is set for a month (30 days) prior to the Date.renewalEndDate
    static let renewalLateFeeStartDate: Date = Date.now.addingTimeInterval((86400 * 1095) - (86400 * 30))
    
    // Property for providing a reasonable probationary end date for a given credential disciplinary action item
    /// Computed constant date that is set for 90 days from the current date and time
    static let probationaryEndDate: Date = Date.now.addingTimeInterval(86400 * 90)
    
    /// Computed static property for providing a reasonable renewal period application start date.  Value
    /// is based on the renewalStartDate property and adds 2.5 years to that date (913 days).
    static let renewalBeginsOnDate: Date = Date.renewalStartDate.addingTimeInterval(86400 * 913)
    
    /// Computed static property for providing a reasonable date for when a credential holder completes
    /// the renewal process, which in this case is 20 days after the renewalBeginsOnDate.
    static let renewalCompletedOnDate: Date = Date.renewalBeginsOnDate.addingTimeInterval(86400 * 20)
    
    /// Computed static property for providing a reasonable date with the CeActivity's registrationDeadline property,
    /// when used with the ceRegistrationDeadline helper property.  Constant value that is 30 days ahead of the current
    /// date and time.
    static let registrationDeadlineDate: Date = Date.now.addingTimeInterval(86400 * 30)
    // MARK: - COMPUTED PROPERTIES
    
    // Getting a year string from a given date
    var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return String(year)
    }//: yearString
    
    var standardizedDate: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }//: standardizedDate
    
    
    // MARK: - METHODS
    
    /// Date method that converts any Date into a hyphened MM-DD-YYYY format as a String
    /// - Returns: String consisting of "MM-DD-YYYY"
    func formatDateIntoHyphenedString() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        
        return "\(month)-\(day)-\(year)"
    }//: formatDateIntoHyphenedString()
    
}//: EXTENSION (DATE)

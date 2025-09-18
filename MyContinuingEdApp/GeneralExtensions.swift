//
//  GeneralExtensions.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/21/25.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}


extension Date {
     
    // Adding a property that will provide a reasonable future expiration date for new CE activities
    static let futureExpiration: Date = Date.now.addingTimeInterval(86400 * 730)
    
    // Property for providing a more reasonable future completion date for new CE activities
    static let futureCompletion: Date = Date.now.addingTimeInterval(86400 * 180)
    
    // Property for providing a reasonable renewal period start date
    static let renewalStartDate: Date = Date.now.addingTimeInterval(86400 * -180)
    
    // Property for providing a reasonable renewal period end date
    static let renewalEndDate: Date = Date.now.addingTimeInterval(86400 * 1095)
    
    // Property for providing a reasonable late fee start date for a given renewal period
    static let renewalLateFeeStartDate: Date = Date.now.addingTimeInterval((86400 * 1095) - (86400 * 30))
    
    // Property for providing a reasonable probationary end date for a given credential disciplinary action item
    static let probationaryEndDate: Date = Date.now.addingTimeInterval(86400 * 90)
    
    // Getting a year string from a given date
    var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return String(year)
    }
}

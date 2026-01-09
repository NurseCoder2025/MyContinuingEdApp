//
//  GeneralExtensions.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/21/25.
//

import Foundation
import SwiftUI

extension Collection {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
}

extension Collection where Element: Equatable {
    
    /// Method that performs the opposite of the .contains method. If the collection does NOT contain the given item,
    /// true will be returned; otherwise, false.
    /// - Parameter element: Any data type that conforms to Equatable
    /// - Returns: True if the element is not present in the collection; otherwise false
    ///
    /// The purpose of this method is to enhance code readability by avoiding the use of  !item.contains syntax.  This method is part
    /// of an extension on the Collection protocol, so any conforming member that has elements conforming to equatable can use it.
    func doesNOTContain(_ element: Element) -> Bool {
        return !self.contains(element)
    }
}//: EXTENSION (collection)


extension Date {
     
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
    
    // Getting a year string from a given date
    var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return String(year)
    }
}


extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }//: dismissKeyboard
}

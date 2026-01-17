//
//  GeneralExtensions.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/21/25.
//

import Foundation
import SwiftUI

// MARK: - COLLECTION Extensions
extension Collection {
    /// Computed property within the Collection extension that returns the opposite value of .isEmpty
    ///
    /// Can be used on any data type that conforms to the Collection protocol
    var isNotEmpty: Bool {
        return !self.isEmpty
    }//: isNotEmpty
    
}//: EXTENSION (Collection)

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
    }//: doesNOTContain
    
}//: EXTENSION (collection)

// MARK: - DATE Extensions
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
    
    // Getting a year string from a given date
    var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return String(year)
    }
}

// MARK: - VIEW Extensions
extension View {
    
    /// Method that dismisses the on-screen keyboard using the UIApplication shared singleton
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }//: dismissKeyboard
}//: EXTENSION (View)


// MARK: - DOUBLE & INT Extensions

extension Double {
    
    /// Constant property for the Double data type whose value is 36,000 (60 x 60 x 10), representing
    /// the number of seconds to be added to a notification trigger date value.  This value is intended
    /// to standardize the timing of notifications when they appear.
    ///
    /// If using, then it is important that the trigger date for the notification be set using the Calendar's
    /// startOfDay(for:) method so that the seconds represented by this constant set the notification time to
    /// whichever hour of the day (final number in multiplication sequence) is desired.  Currently, the value of
    /// 10 should cause the trigger time to be 10am on the day the notification is presented so long as the
    /// startOfDay(for) method was used.
    static let morningNotificationTimeAdjustment: Double = Double (60 * 60 * 10)
    
    /// /// Constant property for the Double data type whose value is 54,000 (60 x 60 x 15), representing
    /// the number of seconds to be added to a notification trigger date value.  This value is intended
    /// to standardize the timing of notifications when they appear.
    ///
    /// If using, then it is important that the trigger date for the notification be set using the Calendar's
    /// startOfDay(for:) method so that the seconds represented by this constant set the notification time to
    /// whichever hour of the day (final number in multiplication sequence) is desired.  Currently, the value of
    /// 15 should cause the trigger time to be 3pm on the day the notification is presented so long as the
    /// startOfDay(for) method was used.
    static let afternoonNotificationTimeAdjustment: Double = Double(60 * 60 * 15)
    
    /// /// Constant property for the Double data type whose value is 68,400 (60 x 60 x 19), representing
    /// the number of seconds to be added to a notification trigger date value.  This value is intended
    /// to standardize the timing of notifications when they appear.
    ///
    /// If using, then it is important that the trigger date for the notification be set using the Calendar's
    /// startOfDay(for:) method so that the seconds represented by this constant set the notification time to
    /// whichever hour of the day (final number in multiplication sequence) is desired.  Currently, the value of
    /// 19 should cause the trigger time to be 7pm on the day the notification is presented so long as the
    /// startOfDay(for) method was used.
    static let eveningNotificationTimeAdjustment: Double = Double(60 * 60 * 19)
    
}//: DOUBLE

// MARK: - IMAGE RELATED


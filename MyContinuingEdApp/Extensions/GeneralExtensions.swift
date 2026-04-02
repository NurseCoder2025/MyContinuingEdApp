//
//  GeneralExtensions.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/21/25.
//

import CloudKit
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

// MARK: - OTHERS

// CKRecordValueProtocol conformance is needed
// for saving certificate and audio media file
// data model structs to iCloud using CloudKit
extension UUID: @retroactive CKRecordValueProtocol {
}//: EXTENSION

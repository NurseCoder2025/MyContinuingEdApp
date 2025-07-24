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
}

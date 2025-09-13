//
//  RenewalPeriod+CoreDataClass.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/8/25.
//
//

import Foundation
import CoreData

@objc(RenewalPeriod)
public class RenewalPeriod: NSManagedObject {
    // MARK: - FUNCTIONS
    
    /// Overriding the willSave function for the class by adding the functionality
    /// from the updatePeriodName method to Apple's built-in willSave
    /// methods whenever a RenewalPeriod object is to be saved.  This should
    /// ensure that the periodName property is updated before the object
    /// gets saved.
    public override func willSave() {
        super.willSave()
        updatePeriodName()
    }
    
    
    /// The updatePeriodName creates a specific text string for a given renewal period
    /// object, either returning just a single year or a range of years.  This function
    /// will then update the periodName property for the RenewalPeriod class.
    private func updatePeriodName() {
        guard periodStart != nil else { return }
        
        let startYear = periodStart?.yearString ?? ""
        let endYear = periodEnd?.yearString ?? ""
        let newRenewalPeriodName: String
        
        if startYear == endYear || endYear.isEmpty {
            newRenewalPeriodName = "\(startYear) Renewal"
        } else  {
            newRenewalPeriodName = "\(startYear) - \(endYear) Renewal"
        }
        
        if periodName != newRenewalPeriodName {
            periodName = newRenewalPeriodName
        }
        
    } //: updatePeriodName()

}

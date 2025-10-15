//
//  RenewalPeriod-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation

// MARK: CoreData Helpers
extension RenewalPeriod {
    
    var renewalPeriodStart: Date {
        get { periodStart ?? Date.renewalStartDate}
        set { periodStart = newValue }
    }
    
    var renewalPeriodEnd: Date {
        get { periodEnd ?? Date.renewalEndDate }
        set { periodEnd = newValue }
    }
    
    var renewalLateFeeStartDate: Date {
        get {lateFeeStartDate ?? Date.renewalLateFeeStartDate}
        set {lateFeeStartDate = newValue}
    }
    
    var renewalPeriodUID: UUID {
        periodID ?? UUID()
    }
    
    /// No getter for the renewalPeriodName computed property as it will
    /// be automatically calculated by the generateRenewalPeriodName property
    var renewalPeriodName: String {
        get { periodName ?? ""}
    }
    
    
    
    // Computed property that returns all activities that fall within the
    // current (selected) renewal period
    var renewalCurrentActivities: [CeActivity] {
        let renewalStart = self.renewalPeriodStart
        let renewalEnd = self.renewalPeriodEnd
        
        let result = cesCompleted?.allObjects as? [CeActivity] ?? []
        return result.filter {
            var filterResult: Bool = false
            if let completionDate = $0.dateCompleted {
                filterResult = completionDate >= renewalStart && completionDate <= renewalEnd
            } //: IF LET
            return filterResult
        } //: FILTER
    }
}


// MARK: Renewal Period EXAMPLE
extension RenewalPeriod {
    
    // Creating an example for previewing purposes
    static var example: RenewalPeriod {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let newPeriod = RenewalPeriod(context: viewContext)
        newPeriod.periodStart = Date.renewalStartDate
        newPeriod.periodEnd = Date.renewalEndDate
        
        return newPeriod
    }
}



//
//  RenewalPeriod-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation

// MARK: CoreData Helpers
extension RenewalPeriod {
    // For each of the dates connected with each RenewalPeriod object, a custom getter was needed in
    // order to more easily compare just the date components (MM/DD/YYYY) with another date in
    // various functions throughout the app, especially the notification ones.  All date values
    // returned will have standardized time components (12:00:00) which will allow for the comparing
    // of dates.
    
    var renewalPeriodStart: Date {
        get {
            let calendar = Calendar.current
            let renewalStart = calendar.startOfDay(for: periodStart ?? Date.renewalStartDate)
            return renewalStart
        }
        
        set { periodStart = newValue }
    }
    
    var renewalPeriodEnd: Date {
        get {
            let calendar = Calendar.current
            let renewalEnd = calendar.startOfDay(for: periodEnd ?? Date.renewalEndDate)
            return renewalEnd
        }
        
        set { periodEnd = newValue }
    }
    
    var renewalLateFeeStartDate: Date {
        get {
            let calendar = Calendar.current
            let lateFeeStart = calendar.startOfDay(for: lateFeeStartDate ?? Date.renewalLateFeeStartDate)
            return lateFeeStart
        }
        
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


// MARK: - Renewal Period EXAMPLE
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



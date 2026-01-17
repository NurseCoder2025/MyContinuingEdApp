//
//  RenewalPeriod-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation


extension RenewalPeriod {
    // MARK: - CoreData Helpers
    // For each of the dates connected with each RenewalPeriod object, a custom getter was needed in
    // order to more easily compare just the date components (MM/DD/YYYY) with another date in
    // various functions throughout the app, especially the notification ones.  All date values
    // returned will have standardized time components (12:00:00) which will allow for the comparing
    // of dates.
    
    /// Computed CoreData property helper for RenewalPeriod that returns & sets a date for the periodStart property.
    ///
    /// This property represents the first day of a complete renewal cycle and not the date when credential holders
    /// can begin applying to renew their credential with the governing body.
    ///
    /// For example, if a renewal cycle is 2 years long, and begins on June 1st of the year, then the periodStart is
    /// June 1st.  However, credential holders usually have to apply to renew their credential before that date, like
    /// April 1st, with May 31st as the deadline to renew.  The application window dates are represented by the
    /// other RenewalPeriod properties of renewalBeginsOn and renewalDeadline.
    var renewalPeriodStart: Date {
        get {
            let calendar = Calendar.current
            let renewalStart = calendar.startOfDay(for: periodStart ?? Date.renewalStartDate)
            return renewalStart
        }
        
        set { periodStart = newValue }
    }
    
    /// Computed CoreData property helper for RenewalPeriod that returns & sets a date for the periodEnd property.
    ///
    /// This property represents the final day of a complete renewal cycle when the credential is considered to be
    /// active and in effect.  If a credential holder fails to renew before this day, then the credential is considered to
    /// be lapsed and requires reinstatement with the credential's governing body.
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
    
    /// CoreData property helper for the RenewalPeriod's renewalBeginsOn property to make UI integration easier.
    ///
    /// The renewalBeginsOn property represents the first day on which credential holders are allowed by the
    /// governing body to start renewing their credential ahead of the renewal period's end.  If, for example, a credential
    /// is valid from June 1st of one year to May 31st of the following year, then usually the governing body will
    /// allow credential holders to begin renewing around April 1st so they have time to submit the required
    /// renewal application and fees.
    var renewalBeginsOn: Date {
        get {
            let calendar = Calendar.current
            let renewalBeginsOn = calendar.startOfDay(for: periodBeginsOn ?? Date.renewalStartDate)
            return renewalBeginsOn
        }
        set {periodBeginsOn = newValue}
    }//: renewRenealBeginsOn
    
    /// CoreData property helper for the RenewalPeriod's renewalCompletedDate property.  This represents the day
    /// on which the user actually submitted the renewal application and fees for their credential.  Both gets and
    /// sets the value for the renewalCompletedDate property.
    ///
    /// This date is not to be confused with the periodEnd date property as that is the day on which the credential
    /// expires if not renewed before midnight on that day.
    var renewRenewalCompletedDate: Date {
        get {
            let calendar = Calendar.current
            let existingDate = calendar.startOfDay(for: renewalCompletedDate ?? Date.futureCompletion)
            return existingDate
        }
        set {renewalCompletedDate = newValue}
    }//: renewRenewalCompletedDate
    
    
    // MARK: - RELATIONSHIPS
    /// Computed property that returns all completed activities that fall within the
    /// current (selected) renewal period
    ///
    /// Due to the fact that CeActivity objects are ONLY assigned to a RenewalPeriod by the
    /// assignActivitiesToRenewalPeriods method (DataController-Automation) when activities are marked as
    /// completed by the user and have a completion date value that falls within the renewal period's starting and
    /// ending dates, it is safe to simply return all objects in the cesCompleted Set.
    var completedRenewalActivities: [CeActivity] {
        return cesCompleted?.allObjects as? [CeActivity] ?? []
    }//: renewalCurrentActivities
    
    /// RenewalPeriod computed  property that returns an array of CeActivities
    /// that are completed within the RenewalPeriod timeframe, and have
    /// an assigned SpecialCategory object to them.
    var completedActivitiesWithSpecialCats: [CeActivity] {
        completedRenewalActivities.filter {
            $0.specialCat != nil
        }
    }//: completedActivitiesWithSpecialCats
    
}//: EXTENSION


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



//
//  Filter.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import Foundation

struct Filter: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var minModificationDate: Date = Date.distantPast
    var tag: Tag?
    var renewalPeriod: RenewalPeriod?
    var credential: Credential?
    
    // MARK: - OTHER COMPUTED PROPERTIES
    
    /// Computed Filter property that returns an Int of how many CeActivities are in a Tag object's "activities"
    /// Set depending on the badge preference set by the user. If the user selected only active items or completed
    /// items only, then the count will only reflect the number of CeActivities that meet the corresponding criteria.
    ///
    /// - Note: By default, all CeActivity objects associated with a given tag will be counted and returned.  This
    /// property relies on the value of the tagBadgeCountOf settings key in DataController's sharedSettings @Published
    /// property.  However, if the key happens to not yet be initialized, then all activities will be counted.
    ///
    /// Refer to the Tag-CoreDataHelper file for the three different computed properties that return the three different
    /// arrays which this property applies the count method to.  An in-memory DataController instance is created in
    /// this property in order to access the settings value.
    var tagActivitiesCount: Int {
        let controller = DataController(inMemory: true)
        let badgeCountPreference = controller.tagBadgeCountOf
        
        if badgeCountPreference == BadgeCountOption.activeItems.rawValue {
            return tag?.tagActiveActivities.count ?? 0
        } else if badgeCountPreference == BadgeCountOption.completedItems.rawValue {
            return tag?.tagCompletedActivities.count ?? 0
        } else {
            return tag?.tagAllActivities.count ?? 0
        }
    }//: tagActivitiesCount
    
    
    /// Compluted Filter property that returns an Int (at least 0) of how many CeActivities are in the associated
    /// RenewalPeriod's cesCompleted Set.
    ///
    /// See RenewalPeriod-CoreDataHelper file for the completedRenewalActivities computed property which returns
    /// the array of CeActivities to be counted.
    var renewalActivitiesCount: Int {
        renewalPeriod?.completedRenewalActivities.count ?? 0
    }//: renewalActivitiesCount
    
    // MARK: - "Smart Filter" properties
    static var recentActivities = Filter(
        name: "Recent",
        icon: "tray",
        minModificationDate:  Date.now.addingTimeInterval(86400 * -7)
    )
    
    static var allActivities = Filter(name: "All CE Activities", icon: "clock")
    
    // MARK: - PROTOCOL CONFORMANCE
    
    /// Customizing the hash function for this struct by only hasing the id value for each filter as that is the
    /// only value that matters for the puroses of this app.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Customizing the equatable function in order to compare different filters by their respective ids.
    static func ==(lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id
    }
    
}//: STRUCT

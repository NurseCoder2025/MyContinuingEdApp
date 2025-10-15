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
    var tagActivitiesCount: Int {tag?.tagActiveActivities.count ?? 0}
    var renewalActivitiesCount: Int {renewalPeriod?.renewalCurrentActivities.count ?? 0}
    
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
    
}

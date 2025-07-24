//
//  CEActivity-CoreDateHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/16/25.
//

import Foundation

extension CeActivity {
    // Extending CEActivity to handle Core Data optionals easier
    
    var ceTitle: String {
        get { activityTitle ?? "" }
        set { activityTitle = newValue}
    }
    
    var ceDescription: String {
        get { activityDescription ?? "" }
        set { activityDescription = newValue }
    }
    
    var ceActivityCEType: String {
        get { ceType ?? "" }
        set { ceType = newValue }
    }
    
    var ceActivityFormatType: String {
        get { formatType ?? "" }
        set { formatType = newValue }
    }
    
    var ceActivityWhatILearned: String {
        get { whatILearned ?? "" }
        set { whatILearned = newValue }
    }
    
    var ceActivityCompletedDate: Date {
        get {dateCompleted ?? .now }
        set {dateCompleted = newValue}
    }
    
    var ceActivityExpirationDate: Date {
        get {expirationDate ?? .now }
        set {expirationDate = newValue}
    }
    
    var ceActivityModifiedDate: Date {
        modifiedDate ?? .now
    }
    
    var ceActivityAddedDate: Date {
        activityAddedDate ?? .now
    }
    
    // MARK: - Tag-related properties
    var activityTags: [Tag] {
        let result = activity_tags?.allObjects as? [Tag] ?? []
        return result.sorted()
    }
    
    var allActivityTagString: String {
        // making sure there are tags in the tag property
        guard let activity_tags else { return "No tags"}
        
        if activity_tags.count == 0 {
            return "No tags"
        } else {
            return activityTags.map(\.tagTagName).formatted()
        }
        
    }
    
    // MARK: - Example Activity
    static var example: CeActivity {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let activity = CeActivity(context: viewContext)
        activity.activityTitle = "Example CE Activity"
        activity.ceType = "CME"
        activity.formatType = "Recorded Webinar"
        activity.contactHours = 1.0
        activity.cost = 50.00
        activity.activityDescription = "A sample activity that enhanced your professional growth"
        activity.activityCompleted = true
        activity.expirationDate = Date.now.addingTimeInterval(86400 * 30)
        activity.evalRating = 3
        activity.whatILearned = "How to create new CE activities in the tracker"
        
        return activity
    }
    
}

// MARK: - Conforming CeActivity to Comparable
extension CeActivity: Comparable {
    public static func <(lhs: CeActivity, rhs: CeActivity) -> Bool {
        let left = lhs.ceTitle.localizedLowercase
        let right = rhs.ceTitle.localizedLowercase
        
        if left == right {
            return lhs.ceDescription < rhs.ceDescription
        } else {
            return left < right
        }
    }
}


// MARK: - Adding computed expiration status property
extension CeActivity {
    
    // computed property to determine if the given activity will be expiring soon or not
    var expirationStatus: ExpirationType {
        let expiration = ceActivityExpirationDate
        let monthOut: Double = 86400 * 30
        
        if activityCompleted {
            return .finishedActivity
        } else if expiration < Date.now {
            return .expired
        } else if expiration == Date.now {
            return .finalDay
        } else if expiration <= Date.now.addingTimeInterval(monthOut) {
            return .expiringSoon
        } else {
            return .stillValid
        }
    }
    
    var expirationStatusString: String {
        return expirationStatus.rawValue
    }
    
}




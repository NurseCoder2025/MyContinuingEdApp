//
//  CEActivity-CoreDateHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/16/25.
//

import CoreData
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
    
    
    var ceActivityFormat: String {
        get { activityFormat ?? "" }
        set { activityFormat = newValue }
    }
    
    var ceActivityWhatILearned: String {
        get { whatILearned ?? "" }
        set { whatILearned = newValue }
    }
    
    // Removing this part of the helper as activities that aren't completed
    // shouldn't have a date value at all (should be nil)
//    var ceActivityCompletedDate: Date {
//        get {dateCompleted ?? .futureCompletion }
//        set {dateCompleted = newValue}
//    }
    
    // Removing this part of the helper so activities that don't have
    // an expiration date don't get assigned a random value
//    var ceActivityExpirationDate: Date {
//        get {expirationDate ?? .futureExpiration }
//        set {expirationDate = newValue}
//    }
    
    var ceActivityModifiedDate: Date {
        modifiedDate ?? .now
    }
    
    var ceActivityAddedDate: Date {
        activityAddedDate ?? .now
    }
    
    // MARK: - Tag-related properties
    var activityTags: [Tag] {
        let result = tags?.allObjects as? [Tag] ?? []
        return result.sorted()
    }
    
    var allActivityTagString: String {
        // making sure there are tags in the tag property
        guard let tags else { return "No tags"}
        
        if tags.count == 0 {
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
        
        // MARK: CE Designation
        let sampleDesignation = CeDesignation(context: viewContext)
        sampleDesignation.designationName = "Nursing Continuing Education"
        sampleDesignation.designationAbbreviation = "Nursing CE"
        sampleDesignation.designationAKA = "Continuing Nursing Education (CNE)"
        activity.designation = sampleDesignation
        
        activity.activityFormat = "Webinar"
        activity.ceAwarded = 1.0
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
    
    // computed property to determine if the given activity will be
    // expiring soon or not
    
    // Updated 8/12/25 to reflect the fact I removed the expirationDate
    // getter and setter from the helper file in order to keep nil values
    // nil (and not replaced with an arbitrary fill-in value).
    var expirationStatus: ExpirationType {
        if let expiration = expirationDate {
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
            
        } //: IF LET
        
        // If there is NO expiration date for an activity, return either
        // that it has been completed or it is still valid
        if activityCompleted {
            return .finishedActivity
        } else {
            return .stillValid
        }
        
    }
    
    var expirationStatusString: String {
        return expirationStatus.rawValue
    }
    
}

// MARK: - Designation ID Computed Property
// Adding another extension to allow for CeDesignation objects to be identified by
// SwiftUI
extension CeActivity {
    var designationID: NSManagedObjectID? {
        get { designation?.objectID }
        set {
            if let newID = newValue,
               let context = self.managedObjectContext,
               let newDesignation = try? context.existingObject(with: newID) as? CeDesignation {
                self.designation = newDesignation
            }
        }
    }
    
}


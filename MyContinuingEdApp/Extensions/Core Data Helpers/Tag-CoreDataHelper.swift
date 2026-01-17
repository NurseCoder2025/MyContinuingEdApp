//
//  Tags-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/16/25.
//

import Foundation

extension Tag {
    // Making it easier to handle Core Data optional properties
    // MARK: - CORE DATA HELPERS
    var tagTagName: String {
        tagName ?? ""
    }
    
    var tagTagID: UUID {
        tagID ?? UUID()
    }
    
    // MARK: - RELAIONSHIP PROPERTIES
    
    /// Computed CoreData helper property that returns an array of all CeActivity
    /// objects currently in the Tag "activities" Set.
    var tagAllActivities: [CeActivity] {
        let result = activities?.allObjects as? [CeActivity] ?? []
        return result
    }//: tagAllActivities
    
    /// Computed CoreData helper property that returns an array of all CeActivity
    /// objects in the Tag "activity" Set which are not marked as being completed.
    ///
    /// - Note: This property is used in the Filter object definition as part of another
    /// computed property, tagActivitiesCount, which basically just calls the .count
    /// method on the property and returns the result as an Int value.
    var tagActiveActivities: [CeActivity] {
        let result = activities?.allObjects as? [CeActivity] ?? []
        return result.filter {$0.activityCompleted == false}
     }//: tagActiveActivities
    
    /// Computed CoreData helper property that returns an array of all completed
    /// CeActivity objects currently in the Tag "activities" Set.
    var tagCompletedActivities: [CeActivity] {
        let result = activities?.allObjects as? [CeActivity] ?? []
        return result.filter {$0.activityCompleted == true}
    }//: tagCompletedActivities
    
    // MARK: - Sample Tag
    static var example: Tag {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let tag = Tag(context: viewContext)
        tag.tagID = UUID()
        tag.tagName = "Example Tag"
        
        return tag
    }
    
}//: EXTENSION

// MARK: - PROTOCOL CONFORMANCE
extension Tag: Comparable {
    // Making the Tag class conform to Comparable so arrays of tags can be sorted
    
    public static func <(lhs: Tag, rhs: Tag) -> Bool {
        let left = lhs.tagTagName.localizedLowercase
        let right = rhs.tagTagName.localizedLowercase
        
        if left == right {
            return lhs.tagTagID.uuidString < rhs.tagTagID.uuidString
        } else {
            return left < right
        }
    }//: public static func <
}//: EXTENSION

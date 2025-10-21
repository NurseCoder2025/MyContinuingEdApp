//
//  Tags-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/16/25.
//

import Foundation

extension Tag {
    // Making it easier to handle Core Data optional properties
    
    var tagTagName: String {
        tagName ?? ""
    }
    
    var tagTagID: UUID {
        tagID ?? UUID()
    }
    
    var tagActiveActivities: [CeActivity] {
        let result = activity?.allObjects as? [CeActivity] ?? []
        return result.filter {$0.activityCompleted == false}
     }
    
    // MARK: - Sample Tag
    static var example: Tag {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let tag = Tag(context: viewContext)
        tag.tagID = UUID()
        tag.tagName = "Example Tag"
        
        return tag
    }
    
}


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
    }
}

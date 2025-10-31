//
//  DataController-Tags.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//


// Purpose: Due to the large size of the DataController class, separating out functions with similar
// functionality in order to improve code organization and readability.

import CoreData
import Foundation


extension DataController {
    // MARK: - Tag Related Methods
    func missingTags(from activity: CeActivity) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []
        
        let tagSet = Set(allTags)
        let difference = tagSet.symmetricDifference(activity.activityTags)
        
        return difference.sorted()
        
    }
    
    func createNewTag() {
        let newTag = Tag(context: container.viewContext)
        newTag.tagID = UUID()
        newTag.tagName = "New tag"
        
        save()
    }
    
    
}//: DataController

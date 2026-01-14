//
//  DataController-ComputedProperties.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large size of the DataController class, separating out functions with similar
// functionality in order to improve code organization and readability.

import CoreData
import Foundation

extension DataController {
    // MARK: - COMPUTED PROPERTIES
    // Computed property to return an array of tokens for use in the search field in ContentView
    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {return []}
        
        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()
        
        if trimmedFilterText.isNotEmpty {
            request.predicate = NSPredicate(format: "tagName CONTAINS[c] %@", trimmedFilterText)
        }
        
        return (try? container.viewContext.fetch(request).sorted()) ?? []
    
    }
    
    
    // MARK: Managed Object Model (for init)
    
    /// The static model property creates a singleton for the app's data model so it can be used across DataController instances
    /// during testing, previewing, or working code.  This helps avoid Core Data related fatal errors where a "fetch request must have
    /// an entity" is triggered.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "CEActivityModel", withExtension: "momd") else {
            fatalError("Failed to locate the app's primary data model.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load the app's primary data model")
        }
        
        return managedObjectModel
    }()
    
    // MARK: - Standardized Objects
    // These computed properties return all pre-created objects within
    // the app such as ActivityType and USState that the user will
    // never edit or delete
    
    /// Computed property that returns an array of all ActivityType objects that are created
    /// using the Activity Types.json file, sorted by name.  If it just so happens that there aren't
    /// any objects saved to the viewContext when this property is called (highly unlikely), then
    /// the preloadActivityTypes method will be called to save them to storage first.
    var allActivityTypes: [ActivityType] {
        let context = container.viewContext
        let atFetch = ActivityType.fetchRequest()
        atFetch.sortDescriptors = [
            NSSortDescriptor(key: "typeName", ascending: true)
        ]
        let typeCount = (try? context.count(for: atFetch)) ?? 0
        
        if typeCount == 0 {
            preloadActivityTypes()
        }
        
        let allTypes = (try? context.fetch(atFetch)) ?? []
        return allTypes
    }//: allActivityTypes
    
}//: DataController

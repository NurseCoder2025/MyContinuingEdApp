//
//  SpotlightCentral.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/28/25.
//

import CoreData
import CoreSpotlight
import Foundation

final class SpotlightCentral: ObservableObject {
    // MARK: - PROPERTIES
    var dataController: DataController
    var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?
    
    // MARK: - CORE DATA
    
    // MARK: - METHODS
    
    /// Method for retrieving a specific CeActivity object that Core Spotlight located from a user search and then presenting that object to user in the UI
    /// - Parameter uniqueID: String representing the unique identifier of the object from Core Spotlight
    /// - Returns: if a matching object in Core Data is found, the corresponding CeActivity object
    func findCe(with uniqueID: String) -> CeActivity? {
        let container = dataController.container
        
        // 1. Creating a URL object from the string passed in from Core Spotlight
        guard let url = URL(string: uniqueID) else { return nil }
        
        // 2. Use the URL to look up the Core Data identifier
        guard let id = container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else { return nil }
        
        // 3. Use the Core Date identifier to retrieve the actual object
        return try? container.viewContext.existingObject(with: id) as? CeActivity
    }//: findCe(String)
    
    func addCeActivityToIndex(_ item: CeActivity) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        attributeSet.title = item.activityTitle
        attributeSet.contentDescription = item.activityDescription
        
        // Setting a unique id
        let ceIDString = item.activityID?.uuidString ?? UUID().uuidString
        
        // Creating the searchable item for adding to the index
        let searchableItem = CSSearchableItem(uniqueIdentifier: ceIDString, domainIdentifier: nil, attributeSet: attributeSet)
        // Because credential holders must maintain documentation of CEs for a period of ~ 5 - 6 years on average,
        // setting the expiration date for the searchable item for that time so the user can more quickly find it
        // with Spotlight if needed.
        searchableItem.expirationDate = Date().addingTimeInterval(60 * 60 * 24 * 2190)
        
        // Creating the indexes
        let genIndex = CSSearchableIndex.default
        let secureIndex = CSSearchableIndex(name: "secure-index", protectionClass: .complete)
        
        // Adding the item to the secure index
        secureIndex.indexSearchableItems([searchableItem]) { error in
            if error != nil {
                print("Error adding item to secure index: \(error!.localizedDescription)")
            } else {
                print("\(item.ceTitle) was successfully added to secure index")
            }
        }//: secureIndex
    }//: addCeActivityToIndex(CeActivity)
    
    func loadSpotlightItem(_ userActivity: NSUserActivity) {
        if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
            
            dataController.selectedActivity = self.findCe(with: uniqueIdentifier)
            dataController.selectedFilter = .allActivities
        }
    }//: loadSpotlightItem(NSUserActivity)
    
    // MARK: - INIT
    init(dataController: DataController) {
        self.dataController = dataController
        
        // Configuring persisten history tracking
        if let description = dataController.container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Creating indexing delegate
            let coordinator = dataController.container.persistentStoreCoordinator
            spotlightDelegate = NSCoreDataCoreSpotlightDelegate(
                forStoreWith: description,
                coordinator: coordinator
            )
            
            spotlightDelegate?.startSpotlightIndexing()
        }//: IF-LET
        
        
    }//: INIT
    
    
}//: SPOTLIGHT CENTRAL

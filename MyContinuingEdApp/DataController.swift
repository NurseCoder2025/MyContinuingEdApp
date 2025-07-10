//
//  DataController.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    // MARK: - PROPERTIES
    // container for holding the data in memory
    let container: NSPersistentCloudKitContainer  // so we can sync with iCloud
    
    @Published var selectedFilter: Filter? = Filter.allActivities
    
    
    // MARK: - SAVING & DELETING METHODS
    
    /// Save function that will save the context to disk only when changes are made and the function is called.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    /// This delete function is intended for deleting single objects like a single tag or activity. It takes in
    /// a NSManagedObject and notifies all views that the object will be deleted before actually deleting it and
    /// saving the changes to disk.
    func delete(_ object: NSManagedObject) {
        // notifying all views that an object is going to be delete4d
        object.objectWillChange.send()
        // removing the object from the view context
        container.viewContext.delete(object)
        // saving changes to device storage
        save()
    }
    
    /// This PRIVATE delete function is designed for batch delete requests that will be used for testing purposes
    /// only. Must pass in a NSFetchRequest of type NSFetchRequestResult for this function to work.
    /// ** Parameters: **
    ///  - fetchRequest: NSFetchRequest
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        // Wrapping fetchrequest result into a batch request
            let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        // Sending the ids of all fetched objects for deletion
            batchRequest.resultType = .resultTypeObjectIDs
        
        // Delete all objects if the batch delete can be performed as a type cast NSBatchDeleteResult
        if let delete = try? container.viewContext.execute(batchRequest) as? NSBatchDeleteResult {
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObject] ?? []]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
    
    /// The deleteAll function deletes all CE Activities and Tags currently stored in the local storage.  It creates
    /// a fetch request for each object type and calls the private delete function, passing in the fetch request to the
    /// function.
    func deleteAll() {
        // Creating fetch requests for each data object type
        let activityFetch: NSFetchRequest<NSFetchRequestResult> = CeActivity.fetchRequest()
        delete(activityFetch)
        
        let tagFetch: NSFetchRequest<NSFetchRequestResult> = Tags.fetchRequest()
        delete(tagFetch)
        
        save()
    }
    
    
    
    // MARK: - PREVIEW SAMPLE DATA
    
    // Creating sample data for testing and previewing
    func createSampleData() {
        let viewContext = container.viewContext
        let ThirtyDaysInSeconds: Double = 60 * 60 * 24 * 30
        
        // Creating 5 sample activities, and 10 tags per activity
        for i in 1...5 {
            let activity = CeActivity(context: viewContext)
            activity.activityTitle = "Activity # \(i)"
            activity.activityDescription = "A fun and educational CE activity!"
            activity.contactHours = 1.0
            activity.evalRating = 4
            activity.ceType = "Nursing CE"
            activity.activityCompleted = Bool.random()
            activity.expirationDate = Date.now.addingTimeInterval(ThirtyDaysInSeconds)
            activity.cost = 35.0
            activity.formatType = "Recorded Self-Study"
            activity.whatILearned = "A lot!"
            
            for j in 1...10 {
                let tag = Tags(context: viewContext)
                
                tag.tagID = UUID()
                tag.tagName = "Tag #\(j) for activity #\(i)"
            } //: J LOOP
            
        } //: I LOOP
        
        try? viewContext.save()
        
    } //: createSampelData()
    
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        controller.createSampleData()
        return controller
    }()
    
    // MARK: - INITIALIZER
    
    init(inMemory: Bool = false) {
        // identifying the name of the stored data to load and use
        container = NSPersistentCloudKitContainer(name: "CEActivityModel")
        
        // Load data only into memory for testing purposes (if init parameter is set to true)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
    
        // Loading data from local storage
        container.loadPersistentStores { storeDescription, error in
            if error != nil {
                fatalError("Failed to load data from local storage...")
            }
        }
        
        
    } //: INIT
    
} //: DATACONTROLLER

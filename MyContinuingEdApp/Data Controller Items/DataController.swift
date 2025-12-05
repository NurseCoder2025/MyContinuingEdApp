//
//  DataController.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import Foundation
import CoreData

// MARK: - ENUMS




/// A class that handles the creatiion, saving, and deletion of all major objects in this app, including sample data.  It also manages
/// data syncing between iCloud and local storage. Additional functionality such as activity searching and filtering is also handled by
/// methods within this class.
class DataController: ObservableObject {
    // MARK: - PROPERTIES
    // container for holding the data in memory
    let container: NSPersistentCloudKitContainer
    
    
    // Properties for storing the current activity or filter/tag that the user has selected
    @Published var selectedFilter: Filter? = Filter.allActivities
    @Published var selectedActivity: CeActivity?
    
    // Property for storing an ActivityReflection that a user may be searching
    // for in Spotlight
    @Published var selectedReflection: ActivityReflection?
    
    // Properties for holding search terms the user enters for either straight text or tokens
    @Published var filterText: String = ""
    @Published var filterTokens: [Tag] = []
    
    // Properties for sorting and filtering CE activities list
        // MARK: Sorting properties
        @Published var sortType: SortType = .name
        @Published var sortNewestFirst: Bool = true
       
    
        // MARK: Filtering properties
        @Published var filterEnabled: Bool = false
        @Published var filterRating: Int = -1
        @Published var filterExpirationStatus: ExpirationType = .all
        @Published var filterCredential: String = ""
   
    
    // Task property for controlling how often the app saves changes to disk
    private var saveTask: Task<Void, Error>?
    
    // MARK: Spotlight
    var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?
    
    // MARK: In App Purchases
    private var storeTask: Task<Void, Never>?
    private var introEligibilityTask: Task<Void, Never>?
    @Published var isEligibleForIntroOffer: Bool = true
    
   
    // MARK: - SAVING & DELETING METHODS
    
    /// Save function that will save the context to disk only when changes are made and the function is called.
    func save() {
        // Cancel any saves that have been, or are in, the queue
        saveTask?.cancel()
        
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    /// The queueSave function calls the save() function in the DataController but assigns it to a task variable
    /// which will delay saving for 5 seconds unless the action gets cancelled by user behavior.
    func queueSave() {
        saveTask?.cancel()
        
        saveTask = Task { @MainActor in
            try await Task.sleep(for: .seconds(5))
            save()
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
        
        let tagFetch: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(tagFetch)
        
        let activityReflectionFetch: NSFetchRequest<NSFetchRequestResult> = ActivityReflection.fetchRequest()
        delete(activityReflectionFetch)
        
        let renewalPeriodFetch: NSFetchRequest<NSFetchRequestResult> = RenewalPeriod.fetchRequest()
        delete(renewalPeriodFetch)
        
        let credentialFetch: NSFetchRequest<NSFetchRequestResult> = Credential.fetchRequest()
        delete(credentialFetch)
        
        let issuerFetch: NSFetchRequest<NSFetchRequestResult> = Issuer.fetchRequest()
        delete(issuerFetch)
        
        let daiFetch: NSFetchRequest<NSFetchRequestResult> = DisciplinaryActionItem.fetchRequest()
        delete(daiFetch)
        
        save()
    }
    
    
    // MARK: - Cloud storage syncronization methods
    func remoteStorageChanged(_ notification: Notification) {
        objectWillChange.send()
    }
    
    // MARK: - PREVIEW
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        controller.createSampleData()
        return controller
    }()
    
    // MARK: - INITIALIZER
    
    init(inMemory: Bool = false) {
        // Assigning initial value for container
        // Also...assigning the model singleton property to prevent errors coming from multiple
        // DataController instances (due to testing, previewing, etc.)
        container = NSPersistentCloudKitContainer(name: "CEActivityModel", managedObjectModel: Self.model)
        
        storeTask = Task {
            await monitorTransactions()
        }
        
        introEligibilityTask = Task {
           isEligibleForIntroOffer = await self.isUserEligibleForIntroOffer()
        }
        
        // identifying the name of the stored data to load and use
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.persistentStoreDescriptions.first?.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
            NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main,
                using: remoteStorageChanged
            )
        }
        
        // Spotlight configuration & setup
        // Configuring persistent history tracking
        if let description = self.container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
            // Creating indexing delegate
            let coordinator = self.container.persistentStoreCoordinator
            self.spotlightDelegate = NSCoreDataCoreSpotlightDelegate(
                    forStoreWith: description,
                    coordinator: coordinator
                )
                
        }//: IF LET description

        // Loading data from local storage
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                print("Core Data store failed to load: \(error.localizedDescription)")
                fatalError("Failed to load data from local storage: \(error)")
            }
            // for first time app use load "Default CE Designations"
            let request = CeDesignation.fetchRequest()
            let count = (try? self?.container.viewContext.count(for: request))
            if count == 0 {
                self?.preloadCEDesignations()
            }
            // for first time app use or install load default Activity Types
            let typeRequest = ActivityType.fetchRequest()
            let typeCount = (try? self?.container.viewContext.count(for: typeRequest))
            if typeCount == 0 {
                self?.preloadActivityTypes()
            }
            // First-time use/install of app for loading default Countries
            let countryRequest = Country.fetchRequest()
            let countryCount = (try? self?.container.viewContext.count(for: countryRequest))
            if countryCount == 0 {
                self?.preloadCountries()
            }
            // First-time loading of U.S. states list
            let statesRequest = USState.fetchRequest()
            let stateCount = (try? self?.container.viewContext.count(for: statesRequest))
            if stateCount == 0 {
                self?.preloadStatesList()
            }
            
            self?.spotlightDelegate?.startSpotlightIndexing()
        }//: loadPersistentStores
    } //: INIT
    
   
    
} //: DATACONTROLLER

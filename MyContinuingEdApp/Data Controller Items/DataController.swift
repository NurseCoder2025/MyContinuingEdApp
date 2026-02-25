//
//  DataController.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import CloudKit
import CoreData
import StoreKit
import Foundation

/// A class that handles the creatiion, saving, and deletion of all major objects in this app, including sample data.  It also manages
/// data syncing between iCloud and local storage. Additional functionality such as activity searching and filtering is also handled by
/// methods within this class.
class DataController: ObservableObject {
    // MARK: - PROPERTIES
    // container for holding the data in memory
    let container: NSPersistentCloudKitContainer
    
    // shared settings for app with iCloud
    @Published var sharedSettings = NSUbiquitousKeyValueStore.default
    
    // iCloud properties for image & audio syncing
    let fileSystem = FileManager()
    let defaultICloudContainer = CKContainer.default()
    @Published var userICloudID: CKRecord.ID?
    
    /// Published DataController property that holds the URL for the default iCloud ubiqituity container that is set for the
    /// user for this app.  This value is set by the assessUserICloudStatus method.
    @Published var userCloudDriveURL: URL?
    @Published var iCloudAvailability: iCloudStatus = .initialStatus
    @Published var certificateAudioStorage: StorageToUse = .local
    private var iCloudTasks: Task<Void, Never>?
    
    /// Constant DataController property that sets a URL for a directory within the app's
    /// sandbox environment into which CE certificate images/PDFs and audio recordings
    /// can be saved IF the user is not logged into iCloud.  This uses the default documents
    /// directory as the top-level folder.
    ///
    /// - Important: This should ONLY be used if the user either does not have iCloud or
    /// wishes to use it for the app.
    let localStorage = URL.documentsDirectory
   
    
    // Property for showing the activity reflection view
    @Published var showActivityReflectionView: Bool = false
    
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
        @Published var filterLiveActivitiesOnly: Bool = false
   
    
    // Task property for controlling how often the app saves changes to disk
    private var saveTask: Task<Void, Error>?
    
    // MARK: Spotlight
    var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?
    
    // MARK: In App Purchases
    private var storeTask: Task<Void, Never>?
    @Published var products: [Product] = []
    /// String value for displaying to the user which subscription type that they currently have.
    @Published var currentSubscriptionType: String = ""
    
    // MARK: PreLoading Object Properties
    
    /// Private DataController property used for creating a Task for scheduling the execution
    /// of preloading functions.  These functions load pre-made objects for use within the app's UI for
    /// things like CE designation, Countries, States (U.S.), activity types, achievements, & reflection
    /// prompts.  Value is set within the DataController's init method.
    private var preloadTasks: Task<Void, Never>?
   
    // MARK: - SAVING & DELETING METHODS
    
    /// Save function that will save the context to disk only when changes are made and the function is called.
    func save() {
        // Cancel any saves that have been, or are in, the queue
        saveTask?.cancel()
        
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }//: save()
    
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
    
    
    // MARK: - Notification (observer) methods
    
    /// DataController method designed to issue a general change announcement so that
    /// each individual view within the app can respond appropriately whenever this
    /// method is called with the NSPersistentStoreRemoteChange notification.
    /// - Parameter notification: <#notification description#>
    func remoteStorageChanged(_ notification: Notification) {
        objectWillChange.send()
    }// remoteStorageChanged
    
    
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
        
        #if DEBUG
        // Adding this code in order to reset the purchaseStatus key
        // upon deletion of the app and re-install for testing
        // purposes.
            self.sharedSettings.removeObject(forKey: "purchaseStatus")
        #endif
        
        // MARK: Sync Settings
        sharedSettings.synchronize()
        // MARK: MONITOR TRANSACTIONS
        storeTask = Task {
            await monitorTransactions()
        }//: TASK
        
        // identifying the name of the stored data to load and use
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.persistentStoreDescriptions.first?.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
            // MARK: - OBSERVERS
            NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main,
                using: remoteStorageChanged
            )//: OBSERVER
            
            // Observer for updating the UI whenever the system
            // detects a user logging in/out of iCloud OR the data
            // sync setting changes for iCloud Drive
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleUbiquityIdChange(_:)),
                name: .NSUbiquityIdentityDidChange,
                object: nil
            )//: OBSERVER
            
            // Adding an observer for incoming changes to the sharedSettings
            // property as it is an NSUbiquitousKeyValueStore and is synced
            // over iCloud.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleKeyValueStoreChanges(_:)),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: sharedSettings
            )//: OBSERVER
            
            // MARK: ICLOUD TASK
            iCloudTasks = Task {
                await assessUserICloudStatus()
            }//: TASK
            
        }//: IF ELSE
        
        // MARK: - SPOTLIGHT SETUP
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
            
            // MARK: - Spotlight Indexing
            self?.spotlightDelegate?.startSpotlightIndexing()
        }//: loadPersistentStores
        
        // MARK: - Preload Other Objects
        // Using a Task to help improve app performance by scheduling
        // these function calls after the persistent stores are loaded.
        
        preloadTasks = Task {
            await preloadActivityTypes()
            await preloadCEDesignations()
            await preloadCountries()
            await preloadStatesList()
            await preloadAllAchievements()
            await preloadPromptQuestions()
        }//: TASK
        
        
        // MARK: - Setting Key Values
        // First time use determination & setting the key if so
        if isAppRunForFirstTime() {
            isFirstRun = true
        } else {
            isFirstRun = false
        }
        
        // Setting default values for all Settings keys (initial
        // app launch ONLY
        // MARK: Default Settings
        setDefaultSettingsKeys()
        
        
    } //: INIT
    
   
    
} //: DATACONTROLLER

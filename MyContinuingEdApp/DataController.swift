//
//  DataController.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import Foundation
import CoreData

// MARK: - ENUMS
enum SortType: String {
    case name = "activityTitle"
    case dateCreated = "activityAddedDate"
    case dateModified = "modifiedDate"
    case dateCompleted = "dateCompleted"
    case activityCost = "cost"
    case hoursAwarded = "contactHours"
    case typeOfCE = "ceType"
    case format = "formatType"
}


class DataController: ObservableObject {
    // MARK: - PROPERTIES
    // container for holding the data in memory
    let container: NSPersistentCloudKitContainer  // so app can sync with iCloud
    
    // Properties for storing the current activity or filter/tag that the user has selected
    @Published var selectedFilter: Filter? = Filter.allActivities
    @Published var selectedActivity: CeActivity?
    
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
   
    
    // Task property for controlling how often the app saves changes to disk
    private var saveTask: Task<Void, Error>?
    
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
    
    // MARK: - SAVING & DELETING METHODS
    
    /// Save function that will save the context to disk only when changes are made and the function is called.
    func save() {
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
        
        save()
    }
    
    // MARK: - Search & Filter Methods
    
    /// This function stores whatever filter the user has selected into a filter variable, but if none is selected
    /// saves the allActivities smart filter.  A compound NSPredicate is created by this function, and within the
    /// compound predicate is the tag that the user selected (if applicable) as well as the modification date.
    /// A fetch request is created that creates the compound predicates and supplies that to the viewContext's fetch
    /// request, returning an array of any CeActivity objects having the selected tag.
    func activitiesForSelectedFilter() -> [CeActivity] {
        let filter = selectedFilter ?? .allActivities
        var predicates: [NSPredicate] = [NSPredicate]()
        
        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(format: "modifiedDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }
        
        // Adding any selected tokens to the predicates array
        if filterTokens.isNotEmpty {
            let tokenPredicate = NSPredicate(format: "ANY tags IN %@", filterTokens)
            predicates.append(tokenPredicate)
        }
        
        // Adding any selected renewal period to the predicates
        if let renewalPeriod = filter.renewalPeriod {
            let renewalPredicate = NSPredicate(format: "renewal == %@", renewalPeriod)
            predicates.append(renewalPredicate)
        }
        
        // if the user activates the filter feature, add the selected filters to the compound NSPredicate
        if filterEnabled {
            // Rating filter
            if filterRating >= 0 {
                let ratingPredicate = NSPredicate(format: "evalRating = %d", filterRating)
                predicates.append(ratingPredicate)
            }
            // Expiration status filter
            if filterExpirationStatus != .all {
                // All completed activities filter
                let lookForCompleted = filterExpirationStatus == .finishedActivity
                let completedActivityPredicate = NSPredicate(format: "activityCompleted = %@", NSNumber(value: lookForCompleted))
                predicates.append(completedActivityPredicate)
                
                // Finding activities under other statuses
                let otherStatusPredicate = NSPredicate(format: "currentStatus = %@", filterExpirationStatus.rawValue)
                predicates.append(otherStatusPredicate)
                
            }
        } //: IF Filter Enabled
        
        let request = CeActivity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // TODO: Fix sorting problem (sorting doesn't appear to be occurring)
        // For sorting the selected filter/sort items:
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        
        
        let allActivities = (try? container.viewContext.fetch(request)) ?? []
        return allActivities.sorted()
    }
    
    
    
    
    // MARK: - Cloud storage syncronization methods
    func remoteStorageChanged(_ notification: Notification) {
        objectWillChange.send()
    }
    
    // MARK: - Creating NEW objects
    /// createActivity() makes a new instance of a CeActivity object with certain default values
    /// put into place for the activity title, description, expiration date, and such...
    func createActivity() {
        // creating new object in memory
        let newActivity = CeActivity(context: container.viewContext)
        
        // setting up initial values
        newActivity.ceTitle = "New CE Activity"
        newActivity.activityAddedDate = Date.now
        newActivity.contactHours = 1.0
        newActivity.ceDescription = "An exciting learning opportunity!"
        newActivity.formatType = "Recorded webinar"
        newActivity.ceType = "CME"
        newActivity.cost = 0.0
        
        // if user creates a new activity while a specific tag has been selected
        // assign that tag to the new activity
        if let tag = selectedFilter?.tag {
            newActivity.addToTags(tag)
        }
        
        save()
        
        selectedActivity = newActivity
    }
    
    /// Creating a new renewal period for which CEs need to be earned
    func createRenewalPeriod() -> RenewalPeriod {
        let newRenewalPeriod = RenewalPeriod(context: container.viewContext)
        
        // setting up renewal period initial values
        newRenewalPeriod.periodStart = Date.now
        newRenewalPeriod.periodEnd = Date.now.addingTimeInterval(86400 * 730)
        
        save()
        return newRenewalPeriod
    }
    
    /// Creating a new reflection for a given activity. Only two default values are made:
    /// 1. The reflection date and
    /// 2. The UUID value for the id property
    func createNewActivityReflection() {
        let newReflection = ActivityReflection(context: container.viewContext)
        
        newReflection.reflectionID = UUID()
        newReflection.dateAdded = Date.now
        
        save()
    }
    
    
    // MARK: - AWARDS Related Functions
    
    /// Function to count a given object
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    /// The addContactHours function is designed to add up all of the contact
    /// hours returned from a CeActivity fetch request and return that value
    /// as a double which can then be used.
    func addContactHours(for fetchRequest: NSFetchRequest<CeActivity>) -> Double {
        do {
            let fetchResult = try container.viewContext.fetch(fetchRequest)
            
            var totalValue: Double = 0
            let allHours: [Double] = {
                var hours: [Double] = []
                for activity in fetchResult {
                    hours.append(activity.contactHours)
                } //: LOOP
                
                return hours
            }() //: allHours
            
            for hour in allHours {
                totalValue += hour
            }
            
            return totalValue
            
        } catch  {
            print("Error adding contact hours up")
            return 0
        }
        
        
    }
    
        
    // Function to determine whether an award has been earned
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
            // # of hours earned achievements
        case "CEs":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contactHours > %d", 0.0)
            fetchRequest.propertiesToFetch = ["contactHours"]
            
            let totalHours = addContactHours(for: fetchRequest)
            return totalHours >= Double(award.value)
            
        case "completed":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "activityCompleted = true")
            
            let totalCompleted = count(for: fetchRequest)
            return totalCompleted >= award.value
            
        case "tags":
            let fetchRequest = Tag.fetchRequest()
            let totalTags = count(for: fetchRequest)
            return totalTags >= award.value
            
        case "loved":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating = %d", 4)
            let totalLoved = count(for: fetchRequest)
            return totalLoved >= award.value
            
        case "howInteresting":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "evalRating = %d", 3)
            let totalUnliked = count(for: fetchRequest)
            return totalUnliked >= award.value
            
        case "reflections":
            let fetchRequest = ActivityReflection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completedYN = true")
            let totalReflections = count(for: fetchRequest)
            return totalReflections >= award.value
            
        case "surprises":
            let fetchRequest = ActivityReflection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "surpriseEntered = true")
            let totalSurprises = count(for: fetchRequest)
            return totalSurprises >= award.value
            
            // TODO: Determine why the default case is executing each time the award screen
            // shows up. This also happens each time a button is pressed.
        default:
            print("Sorry, but no award to bestow...")
            return false
        
        } //: hasEarned
    }
    
    
    // MARK: - Automation Related Methods
    
    /// Function that finds the appropriate renewal period for each CE activity, if applicable, and assigns the activity to that period.
    func assignActivitiesToRenewalPeriod() {
        let viewContext = container.viewContext
        // Fetching only all completed CE Activities
        let activityRequest: NSFetchRequest<CeActivity> = CeActivity.fetchRequest()
        activityRequest.predicate = NSPredicate(format: "activityCompleted = true")
        let allCompletedActivities = (try? viewContext.fetch(activityRequest)) ?? []
        
        // Fetching all renewal periods
        let renewalRequest: NSFetchRequest<RenewalPeriod> = RenewalPeriod.fetchRequest()
        let allRenewals = (try? viewContext.fetch(renewalRequest)) ?? []
        
        guard allRenewals.isNotEmpty else { return }
        
        // Match each completed activity with the corresponding renewal period based on the completed date
        for activity in allCompletedActivities {
            guard let completedDate = activity.dateCompleted else { continue }
            
            // finding the matching renewal period
            if let matchingRenewal = allRenewals.first(where: {renewal in
                    guard let start = renewal.periodStart, let end = renewal.periodEnd else { return false }
                
                    return completedDate >= start && completedDate <= end
            }) {
                activity.renewal = matchingRenewal
            } else {
                activity.renewal = nil
            }
            
            save()
            
        }//: LOOP
        
    }
    
    
    // MARK: - PREVIEW SAMPLE DATA
    
    // Creating sample data for testing and previewing
    func createSampleData() {
        let viewContext = container.viewContext
        
        // Creating calendar components for the sample renewal period
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let janFirst = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))
        
        
        // Creating renewal period for sample data
        let sampleRenewalPeriod = RenewalPeriod(context: viewContext)
        let sampleStartDate = janFirst ?? Date.now
        sampleRenewalPeriod.periodStart = sampleStartDate
        sampleRenewalPeriod.periodEnd = sampleStartDate.addingTimeInterval(86400 * 730)
        
        
        // Creating 5 sample activities, and 10 tags per activity
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            
            tag.tagID = UUID()
            tag.tagName = "Tag #\(i)"
            
            for j in 1...10 {
                let randomFutureExpirationDate: Double = 86400 * Double(Int.random(in: 1...730))
                let randomPastDate: Double = -(86400 * Double.random(in: 7...180))
                let activity = CeActivity(context: viewContext)
                
                activity.activityAddedDate = Date.now.addingTimeInterval(randomPastDate)
                activity.activityTitle = "Activity # \(j)-\(i)"
                activity.activityDescription = "A fun and educational CE activity!"
                activity.contactHours = Double.random(in: 0.5...10)
                activity.evalRating = Int16.random(in: 0...4)
                activity.ceType = "Nursing CE"
                activity.activityCompleted = Bool.random()
                activity.expirationDate = Date.now.addingTimeInterval(randomFutureExpirationDate)
                activity.dateCompleted = Date.now.addingTimeInterval(randomPastDate)
                activity.currentStatus = activity.expirationStatusString
                activity.cost = Double.random(in: 0...450)
                activity.formatType = "Recorded Self-Study"
                activity.whatILearned = "A lot!"
                tag.addToActivity(activity)
                
                // Adding sample activity reflections
                let reflection = ActivityReflection(context: viewContext)
                reflection.reflectionID = UUID()
                reflection.generalReflection = """
                Wow, this CE course was so helpful and interesting.  Hope to take more
                like this one!
                """
                reflection.reflectionThreeMainPoints = """
                1. Study hard
                2. Get lots of sleep
                3. Eat healthy
                """
                reflection.reflectionSurprises = """
                No real surprises here today...
                """
                activity.reflection = reflection
                
                // assigning each activity to the sample renewal period
                if activity.activityCompleted {
                    activity.renewal = sampleRenewalPeriod
                }
                
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
        
        // Cloudkit Syncronization configuration
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

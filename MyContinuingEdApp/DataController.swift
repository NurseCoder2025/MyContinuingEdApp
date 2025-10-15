//
//  DataController.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import Foundation
import CoreData

// MARK: - ENUMS

/// This enum is used in ContentView for the Sorting menu as a way to easily tag sort values.  Each enum type has a raw String
/// value that corresponds to a CeActivity property that the user can sort on.
enum SortType: String {
    case name = "activityTitle"
    case dateCreated = "activityAddedDate"
    case dateModified = "modifiedDate"
    case dateCompleted = "dateCompleted"
    case activityCost = "cost"
    case awardedCEAmount = "ceAwarded"
    case typeOfCE = "ceType"
    case format = "formatType"
}


class DataController: ObservableObject {
    // MARK: - PROPERTIES
    // container for holding the data in memory
    let container: NSPersistentCloudKitContainer
    
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
        @Published var filterCredential: String = ""
   
    
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
    
    //: MARK: - Credentials Related Methods
    /// This function counts the number of credentials of a given type that have been entered  into the app and returns the number as an Int
    /// that can be passed into the CredentialCatBoxView for display as a badge icon.
    /// **Important:**
    /// the type parameter is assumed to be a  credential type in the plural form (i.e. Licenses, Certifications, etc.) except for "All" which is singular.
    /// If this function is used outside of the CredentialManagementSheet struct (which is where plural forms of credential types are being passed in)
    /// then the function needs to be updated so that singular forms aren't trimmed.
    /// - Parameter type: credential type (String value) - see Credential-CoreDataHelper for extension with String array that holds these values
    /// - Returns: whole number (Int) representing the number of credentials of a specific type stored in persistent storage
    func getNumberOfCredTypes(type: String) -> Int {
        let request = Credential.fetchRequest()
        if type != "all" && type != "" {
            request.predicate = NSPredicate(format: "credentialType == %@", type)
        }
        let count = (try? container.viewContext.count(for: request)) ?? 0
        return count
    }
    
    /// Using a multi-level predicate, this function determines which credentials are currently considered to be encumbered.  The crieteria are as follows:
    ///    1. The credential's isRestricted property is true OR
    ///    2. Disciplinary action has been taken against the credential which is either permanent or has not ended yet AND
    ///    3. The disciplinary action has NOT been appealed.
    /// - Returns: Array of all Credential objects that meet the specified predicate criteria
    func getEncumberedCredentials() -> [Credential] {
        let credFetch = Credential.fetchRequest()
               
        // Predicates for determining if a credential is, indeed, encumbered
        // Credential restriction property predicate
        let restrictionPredicate = NSPredicate(format: "isRestricted == true")
        
        
        // Related disciplinary action predicates
        // The next three predicates are ORed together to determine if any of them are true
        var currentDAIPredicates: [NSPredicate] = []
        // If the disciplinary action end date is not in the past then include it
        let openDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.actionEndDate > %@", Date.now as NSDate)
        currentDAIPredicates.append(openDisciplinaryActionPredicate)
        // Alternatively, if there is no end date for the disciplinary action, include it
        let noEndDateDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.actionEndDate == nil")
        currentDAIPredicates.append(noEndDateDisciplinaryActionPredicate)
        // If the disciplinary action is permanent then also include it
        let permanentDisciplinaryActionPredicate = NSPredicate(format: "ANY disciplinaryActions.temporaryOnly == false")
        currentDAIPredicates.append(permanentDisciplinaryActionPredicate)
        
        // Compound predicate holding the three predicates related to actionEndDate or temporaryOnly properties
        let daiORCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: currentDAIPredicates)
        
        // Adding credential ONLY if action has NOT been appealed
        let notAppealedPredicate = NSPredicate(format: "ANY disciplinaryActions.appealedActionYN == false")
        
        // Creating a compound predicate (AND) with the daiORCompoundPredicate and the notAppealedPredicate
        let combinedDAIPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                daiORCompoundPredicate,
                notAppealedPredicate
            ]
        )
        
        
        // Creating the final combined predicate (OR) to return all encumbered credential objects
        let finalPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: [
            restrictionPredicate,
            combinedDAIPredicate
            ]
        )
        
        // Applying the final predicate to the fetch request
        credFetch.predicate = finalPredicates
        credFetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let encumberedCredentials = (try? container.viewContext.fetch(credFetch)) ?? []
        return encumberedCredentials
    }
    
    // MARK: - PRELOADING  METHODS
    // MARK: CE Designations METHODS
    /// This fucntion decodes all of the default CE designations in the "Defaut CE Designations" JSON file
    ///  and then creates a CeDesignation object for each JSON object IF there are currently no designations
    ///  stored.  This will load default values upon the first use of the app by the user.  Thereafter, the user
    ///  can edit the list as desired.
    func preloadCEDesignations() {
        let request = CeDesignation.fetchRequest()
        let count = (try? container.viewContext.count(for: request)) ?? 0
        guard count == 0 else { return }
        
        let defaultCeDesignations: [CeDesignationJSON] = Bundle.main.decode("Default CE Designations.json")
        
        for designation in defaultCeDesignations {
            let convertedItem = CeDesignation(context: container.viewContext)
            convertedItem.designationAbbreviation = designation.designationAbbreviation
            convertedItem.designationName = designation.designationName
            convertedItem.designationAKA = designation.designationAKA
        }
        save()
    }
    
    // MARK: Preload Countries
    /// Like the preloadCEDesignations method, the preloadCountries creates Country objects
    ///  for each country in the "Country List.json" file and saves them to persistent storage on the
    ///  first run of the app (or whenever the # of countries stored = 0.
    func preloadCountries() {
        let request = Country.fetchRequest()
        let count = (try? container.viewContext.count(for: request)) ?? 0
        guard count == 0 else {return}
        
        let defaultCountries: [CountryJSON] = Bundle.main.decode("Country List.json")
        
        for country in defaultCountries {
            let place = Country(context: container.viewContext)
            place.id = UUID() // Ensure unique identifier
            place.name = country.name
            place.alpha2 = country.alpha2
            place.alpha3 = country.alpha3
            place.sortOrder = country.sortOrder
        }
        
        save()
    
    }
    
    // MARK: Preload ACTIVITY TYPE METHODS
    
    /// Like the preloadCEDesignations() method, this function loads a set of default activity value types into the persisten container
    ///  upon the initial run of the application (or after re-install).  However, after the defaults are created the user can edit them later.
    func preloadActivityTypes() {
        let viewContext = container.viewContext
        let fetchTypes = ActivityType.fetchRequest()
        
        let count = (try? viewContext.count(for: fetchTypes)) ?? 0
        guard count == 0 else { return }
        
        let defaultActivityTypes: [ActivityTypeJSON] = Bundle.main.decode("Activity Types.json")
        
        for type in defaultActivityTypes {
            let item = ActivityType(context: viewContext)
            item.activityTypeName = type.typeName
        }
        
        save()
    }
    
    /// Loads all 50 U.S. state objects as saved in the JSON file within the bundle.  This will be
    /// executed only upon first install of the app.  Thereafter, all 50 values will remain as the user
    /// cannot edit or delete any of these values.
    func preloadStatesList() {
        let viewContext = container.viewContext
        let statesFetch = USState.fetchRequest()
        
        let count = (try? viewContext.count(for: statesFetch)) ?? 0
        guard count == 0 else {return}
        
        let defaultStates = USStateJSON.allStates
        
        for state in defaultStates {
            let item = USState(context: viewContext)
            item.id = UUID()
            item.stateName = state.stateName
            item.abbreviation = state.abbreviation
        }
        
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
        
        // Adding selected credential to the predicates array
        if let chosenCredential = filter.credential {
            let credentialPredicate = NSPredicate(format: "ANY credentials == %@", chosenCredential)
            predicates.append(credentialPredicate)
        }
        
        // Adding any selected renewal period to the predicates
        if let renewalPeriod = filter.renewalPeriod {
            let renewalPredicate = NSPredicate(format: "renewal == %@", renewalPeriod)
            predicates.append(renewalPredicate)
        }
        
        // if the user activates the filter feature, add the selected filters to the compound NSPredicate
        if filterEnabled {
            // Credential filter
            if filterCredential != "" {
                let credPredicate = NSPredicate(format: "ANY credentials IN %@", filterCredential)
                predicates.append(credPredicate)
            }
            
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
        
        // For sorting the selected filter/sort items:
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        
        let allActivities = (try? container.viewContext.fetch(request)) ?? []
        return allActivities
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
        newActivity.ceAwarded = 1.0
        newActivity.ceDescription = "An exciting learning opportunity!"
        newActivity.activityFormat = "Virtual"
       // TODO: Add CE Designation default
        newActivity.cost = 0.0
        newActivity.specialCat = nil
        
        // if user creates a new activity while a specific tag has been selected
        // assign that tag to the new activity
        if let tag = selectedFilter?.tag {
            newActivity.addToTags(tag)
        }
        
        // if the user creates a new activity while a specific renewal period has been
        // selected then the corresponding Credential object will automatically
        // be assigned to the new activity as well as the Renewal Period
        if let renewal = selectedFilter?.renewalPeriod, let credential = renewal.credential {
            newActivity.addToCredentials(credential)
            newActivity.renewal = renewal
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
    func createNewActivityReflection() -> ActivityReflection {
        let newReflection = ActivityReflection(context: container.viewContext)
        
        newReflection.reflectionID = UUID()
        newReflection.dateAdded = Date.now
        
        save()
        return newReflection
    }
    
    
    /// Function to create a new credential object with a default name value.
    /// - Returns: Credential object with default name value
    func createNewCredential() -> Credential {
        let newCredential = Credential(context: container.viewContext)
        
        newCredential.name = "New Credential"
        newCredential.isActive = true
        newCredential.credentialID = UUID()
        // Setting the default credential type to an empty string upon creation
        // so that the user will be prompted to select a type in the picker control
        newCredential.credentialType = ""
        
        save()
        return newCredential
    }
    
    /// Function to create a new Issuer object and save it to persistent storage
    /// - Returns: Issuer object with a UUID and name property set to "New Issuer", along
    ///   with a default country of the United States and state (Alabama)
    func createNewIssuer() -> Issuer {
        let context = container.viewContext
        let newIssuer = Issuer(context: context)
        newIssuer.issuerID = UUID()
        newIssuer.issuerName = "New Issuer"
        
        // Set default country to United States
        let countryRequest: NSFetchRequest<Country> = Country.fetchRequest()
        countryRequest.predicate = NSPredicate(format: "alpha3 == %@", "USA")
        
        let defaultCountry = (try? context.fetch(countryRequest).first) ?? nil
        newIssuer.country = defaultCountry
        
        save()
        return newIssuer
    }
    
    
    /// Function to create a new DisciplinaryActionItem object to be associated with a given Credential. Object creation will take place
    ///  in the DisciplinaryActionListSheet or from the NoDAI view when the appropriate button is tapped.
    /// - Returns: DisciplinaryActionItem object with a default name of "New Action", auto-generated UUID, and default setting of
    ///  temporary action (temporaryOnly)
    func createNewDAI(for credential: Credential) -> DisciplinaryActionItem {
        let context = container.viewContext
        let newDAI = DisciplinaryActionItem(context: context)
        newDAI.disciplineID = UUID()
        newDAI.actionName = "New Action"
        newDAI.temporaryOnly = true
        newDAI.credential = credential
        
        save()
        return newDAI
    }
    
    
    // MARK: - ACHIEVEMENTS Related Functions
    
    /// Function to count a given object
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    /// The addContactHours function is designed to add up all of the contact
    /// hours returned from a CeActivity fetch request and return that value
    /// as a double which can then be used.
    func addAwardedCE(for fetchRequest: NSFetchRequest<CeActivity>) -> Double {
        do {
            let fetchResult = try container.viewContext.fetch(fetchRequest)
            
            var totalValue: Double = 0
            let allCE: [Double] = {
                var hours: [Double] = []
                for activity in fetchResult {
                    hours.append(activity.ceAwarded)
                } //: LOOP
                
                return hours
            }() //: allHours
            
            for ce in allCE {
                totalValue += ce
            }
            
            return totalValue
            
        } catch  {
            print("Error adding awarded CE up")
            return 0
        }
        
        
    }
    
        
    // Function to determine whether an award has been earned
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
            // # of hours earned achievements
        case "CEs":
            let fetchRequest = CeActivity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ceAwarded > %d", 0.0)
            fetchRequest.propertiesToFetch = ["ceAwarded"]
            
            let totalHours = addAwardedCE(for: fetchRequest)
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
    
    /// Function that finds the appropriate renewal period for each CE activity, if applicable, and assigns the activity to that period. The activity
    /// must be completed and have a dateCompleted value in order to be assigned to a renewal period.
    func assignActivitiesToRenewalPeriod() {
        let viewContext = container.viewContext
        
        // Fetching only all completed CE Activities
        let activityRequest: NSFetchRequest<CeActivity> = CeActivity.fetchRequest()
        activityRequest.predicate = NSPredicate(format: "activityCompleted = true")
        let allCompletedActivities = (try? viewContext.fetch(activityRequest)) ?? []
        
        // Fetching all credentials
        let credentialRequest: NSFetchRequest<Credential> = Credential.fetchRequest()
        let allCredentials = (try? viewContext.fetch(credentialRequest)) ?? []
        
        // Fetching all renewal periods
        let renewalRequest: NSFetchRequest<RenewalPeriod> = RenewalPeriod.fetchRequest()
        let allRenewals = (try? viewContext.fetch(renewalRequest)) ?? []
        
        guard allCredentials.isNotEmpty, allRenewals.isNotEmpty else { return }
        
        for activity in allCompletedActivities {
            guard let completedDate = activity.dateCompleted else { continue }
            
            // Find the credential(s) for this activity
            let activityCredentials = activity.credentials as? Set<Credential> ?? []
            
            for credential in activityCredentials {
                // Cast renewals to Set<RenewalPeriod> for type-safe access
                if let renewalsSet = credential.renewals as? Set<RenewalPeriod> {
                    if let matchingRenewal = renewalsSet.first(where: { renewal in
                        guard let start = renewal.periodStart, let end = renewal.periodEnd else { return false }
                        return start <= completedDate && completedDate <= end
                    }) {
                        activity.renewal = matchingRenewal
                        break // Found a match, no need to check other credentials
                    } else {
                        activity.renewal = nil
                    }
                }
            }
        }
        save()
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
        
        // Creating sample Country for Issuer object
        let sampleCountry = Country(context: viewContext)
        sampleCountry.name = CountryJSON.defaultCountry.name
        sampleCountry.alpha2 = CountryJSON.defaultCountry.alpha2
        sampleCountry.alpha3 = CountryJSON.defaultCountry.alpha3
        
        // Creating sample State for Issuer object
        let sampleState = USState(context: viewContext)
        sampleState.stateName = USStateJSON.example.stateName
        sampleState.abbreviation = USStateJSON.example.abbreviation
        
        // Creating Issuer object for the sample Credential
        let sampleIssuer = Issuer(context: viewContext)
        sampleIssuer.issuerName = "Ohio Board of Nursing"
        sampleIssuer.country = sampleCountry
        sampleIssuer.state = sampleState
        
        // Creating Credential object for all sample credentials
        let sampleCredential = Credential(context: viewContext)
        sampleCredential.name = "Ohio RN License"
        sampleCredential.credentialType = "license"
        sampleCredential.isActive = true
        sampleCredential.issueDate = Date.renewalStartDate
        sampleCredential.renewalPeriodLength = 24
        sampleCredential.credentialNumber = "RN123456"
        sampleCredential.issuer = sampleIssuer
        
        // Assigning sample renewal period to the sample credential
        sampleCredential.addToRenewals(sampleRenewalPeriod)
        
        // Creating 5 sample activities, and 10 tags per activity
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            
            tag.tagID = UUID()
            tag.tagName = "Tag #\(i)"
            
            // Activities for each tag
            for j in 1...10 {
                let randomFutureExpirationDate: Double = 86400 * Double(Int.random(in: 1...730))
                let randomPastDate: Double = -(86400 * Double.random(in: 7...180))
                let activity = CeActivity(context: viewContext)
                
                activity.activityAddedDate = Date.now.addingTimeInterval(randomPastDate)
                activity.activityTitle = "Activity # \(j)-\(i)"
                activity.activityDescription = "A fun and educational CE activity!"
                activity.ceAwarded = Double.random(in: 0.5...10)
                activity.hoursOrUnits = Int16.random(in: 1...2)
                activity.evalRating = Int16.random(in: 0...4)
                
                // MARK: Credential assignment
                activity.credentials = [sampleCredential]
                
                // MARK: CE Designation
                let designationRequest: NSFetchRequest<CeDesignation> = CeDesignation.fetchRequest()
                let allDesignations = (
                    try? viewContext.fetch(designationRequest)
                ) ?? []
                
                if allDesignations.isNotEmpty {
                    let designationCount = allDesignations.count
                    let randomIndex = Int.random(in: 0..<designationCount)
                    
                    activity.designation = allDesignations[randomIndex]
                }
                
                // MARK: Sample Activity Format
                let allFormats: [ActivityFormat] = ActivityFormat.allFormats
                let randomFormat = allFormats.randomElement()
                activity.activityFormat = randomFormat?.formatName
                
                // MARK: Sample Activity Type
                let typeRequest = ActivityType.fetchRequest()
                let allTypes = (try? container.viewContext.fetch(typeRequest)) ?? []
                
                if allTypes.isNotEmpty {
                    let typecount = allTypes.count
                    let randomIndex = Int.random(in: 0..<typecount)
                    
                    activity.type = allTypes[randomIndex]
                }
                              
                // MARK: Sample Activity Expiration
                activity.activityExpires = Bool.random()
                if activity.activityExpires {
                    activity.expirationDate = Date.now.addingTimeInterval(randomFutureExpirationDate)
                } else {
                    activity.expirationDate = nil
                }
                
                // MARK: sample activity completion
                activity.activityCompleted = Bool.random()
                if activity.activityCompleted {
                    activity.dateCompleted = Date.now.addingTimeInterval(randomPastDate)
                } else {
                    activity.dateCompleted = nil
                }
                
                activity.currentStatus = activity.expirationStatusString
                activity.cost = Double.random(in: 0...450)
                activity.activityFormat = "Virtual"
                activity.whatILearned = "A lot!"
                tag.addToActivity(activity)
                
                // Adding sample activity reflections IF activity has been
                // completed
                if activity.activityCompleted {
                    let reflection = ActivityReflection(context: viewContext)
                    reflection.reflectionID = UUID()
                    reflection.generalReflection = """
                    Wow, this CE course was so helpful and interesting.  Hope to take more like this one!
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
                }
                
            } //: J LOOP
            
        } //: I LOOP
        
        try? viewContext.save()
        
        // assigning each activity to the sample renewal period
        assignActivitiesToRenewalPeriod()
        
    } //: createSampelData()
    
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        controller.createSampleData()
        return controller
    }()
    
    // MARK: - INITIALIZER
    
    init(inMemory: Bool = false) {
        // Assigning initial value for container
        container = NSPersistentCloudKitContainer(name: "CEActivityModel")
        
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

        // Loading data from local storage
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Core Data store failed to load: \(error.localizedDescription)")
                fatalError("Failed to load data from local storage: \(error)")
            }
            // for first time app use load "Default CE Designations"
            let request = CeDesignation.fetchRequest()
            let count = (try? self.container.viewContext.count(for: request))
            if count == 0 {
                self.preloadCEDesignations()
            }
            // for first time app use or install load default Activity Types
            let typeRequest = ActivityType.fetchRequest()
            let typeCount = (try? self.container.viewContext.count(for: typeRequest))
            if typeCount == 0 {
                self.preloadActivityTypes()
            }
            // First-time use/install of app for loading default Countries
            let countryRequest = Country.fetchRequest()
            let countryCount = (try? self.container.viewContext.count(for: countryRequest))
            if countryCount == 0 {
                self.preloadCountries()
            }
            // First-time loading of U.S. states list
            let statesRequest = USState.fetchRequest()
            let stateCount = (try? self.container.viewContext.count(for: statesRequest))
            if stateCount == 0 {
                self.preloadStatesList()
            }
            
        }
    } //: INIT
    
   
    
} //: DATACONTROLLER

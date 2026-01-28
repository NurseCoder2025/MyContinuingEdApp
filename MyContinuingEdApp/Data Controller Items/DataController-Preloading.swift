//
//  DataController-Preloading.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//


// Purpose: Due to the large size of the DataController class, separating out functions with similar
// functionality in order to improve code organization and readability.

import CoreData
import Foundation


extension DataController {
    // MARK: - PRELOADING  METHODS
    
    // MARK: CE Designations METHODS
    
    /// This fucntion decodes all of the default CE designations in the "Defaut CE Designations" JSON file
    ///  and then creates a CeDesignation object for each JSON object IF there are currently no designations
    ///  stored.  This will load default values upon the first use of the app by the user.  Thereafter, the user
    ///  can edit the list as desired.
    func preloadCEDesignations() async {
        let context = container.viewContext
        let request = CeDesignation.fetchRequest()
        // Ensuring that the fetch count is run on the main thread
        let count = await MainActor.run {
            (try? container.viewContext.count(for: request)) ?? 0
        }
        
        let defaultCeDesignations: [CeDesignationJSON] = Bundle.main.decode("Default CE Designations.json")
        
        guard count == 0 || count < defaultCeDesignations.count else { return }
        
        if count == 0 {
            for designation in defaultCeDesignations {
                let convertedItem = CeDesignation(context: context)
                convertedItem.designationAbbreviation = designation.designationAbbreviation
                convertedItem.designationName = designation.designationName
                convertedItem.designationAKA = designation.designationAKA
            }
        } else {
            // If the complete list of default CeDesignations wasn't loaded for whatever
            // reason, add the missing ones
            let existingDesignations = (try? context.fetch(request)) ?? []
            let existingNames = Set<String>(existingDesignations.map(\.ceDesignationName))
            let officialNamesList = Set<String>(defaultCeDesignations.map(\.designationName))
            let missingNames = officialNamesList.subtracting(existingNames)
            
            if missingNames.isNotEmpty {
                let missingDesignations = defaultCeDesignations.filter {
                    missingNames.contains($0.designationName)
                }
                
                for designation in missingDesignations {
                    let newDesignation = CeDesignation(context: context)
                    newDesignation.designationID = UUID()
                    newDesignation.designationName = designation.designationName
                    newDesignation.designationAbbreviation = designation.designationAbbreviation
                    newDesignation.designationAKA = designation.designationAKA
                }//: LOOP
            }//: IF (missingNames.isNotEmpty)
        }//: IF - ELSE
        
        save()
    }//: preloadCEDesignations()
    
    // MARK: Preload Countries
    /// Like the preloadCEDesignations method, the preloadCountries creates Country objects
    ///  for each country in the "Country List.json" file and saves them to persistent storage on the
    ///  first run of the app (or whenever the # of countries stored = 0).
    func preloadCountries() async {
        let request = Country.fetchRequest()
        // Ensuring that the fetch count is run on the main thread
        let count = await MainActor.run {
            (try? container.viewContext.count(for: request)) ?? 0
        }
        
        guard count == 0 else {return}
        
        let defaultCountries: [CountryJSON] = Bundle.main.decode("Country List.json")
        
        for country in defaultCountries {
            let place = Country(context: container.viewContext)
            place.countryID = UUID() // Ensure unique identifier
            place.name = country.name
            place.alpha2 = country.alpha2
            place.alpha3 = country.alpha3
            place.sortOrder = country.sortOrder
        }
        
        save()
    
    }//: preloadCountries()
    
    // MARK: Preload ACTIVITY TYPE METHODS
    
    /// Like the preloadCEDesignations() method, this function loads a set of default activity
    /// value types into the persistent container upon the initial run of the
    /// application (or after re-install).
    ///
    /// - Note: The number of activity types is pre-determined by the values in the
    /// "Activity Types.json" file contained within the app bundle.  These are NOT user-editable.  If
    /// there is a difference between the number of types in the json file and the objects saved in
    /// CoreData, then this method will add and delete types as applicable.
    func preloadActivityTypes() async {
        let context = container.viewContext
        let fetchTypes = ActivityType.fetchRequest()
        fetchTypes.sortDescriptors = [
            NSSortDescriptor(key: "typeName", ascending: true)
        ]
        // Ensuring that the fetch count runs on the main thread
        let count = await MainActor.run {
            (try? context.count(for: fetchTypes)) ?? 0
        }
        
        let defaultActivityTypes = ActivityTypeJSON.allActivityTypes
        
        guard count == 0 || count != defaultActivityTypes.count else { return }
        
        if count == 0 {
            for type in defaultActivityTypes {
                let item = ActivityType(context: context)
                item.typeID = UUID()
                item.activityTypeName = type.typeName
            }//: LOOP
        } else {
            // If there is a partial list of activity types, then syncronize the
            // ActivityType CoreData objects with the ones in the Activity Type.json
            // file.
            let existingTypes = (try? context.fetch(fetchTypes)) ?? []
            let existingNames = Set<String>(existingTypes.map(\.activityTypeName))
            let officialTypeNames = Set<String>(defaultActivityTypes.map(\.typeName))
            let addedTypeNames = officialTypeNames.subtracting(existingNames)
            let removedTypeNames = existingNames.subtracting(officialTypeNames)
            
            // Any ActivityTpes that have been added but not yet saved as CoreData
            // objects
            if addedTypeNames.isNotEmpty {
                for name in addedTypeNames {
                    let item = ActivityType(context: context)
                    item.typeID = UUID()
                    item.activityTypeName = name
                }//: LOOP
            }//: IF (addedTypeNames.isNotEmpty)
            
            // Deleting any ActivityType objects from CoreData that are no longer
            // in the official list
            if removedTypeNames.isNotEmpty {
                for name in removedTypeNames {
                    let matchingType = existingTypes.first { $0.activityTypeName == name }
                    
                    if let foundType = matchingType {
                        delete(foundType)
                    }//: IF LET
                }//: LOOP
                
            }//: IF (removedTypeNames.isNotEmpty)
            
        }//: IF - ELSE
        
        save()
    }//: preloadActivityTypes()
    
    // MARK: State List
    /// Loads all 50 U.S. state objects as saved in the JSON file within the bundle.  This will be
    /// executed only upon first install of the app.  Thereafter, all 50 values will remain as the user
    /// cannot edit or delete any of these values.
    ///
    /// - Note: Though this method is marked as being "async", due to the need to utilize
    /// CoreData fetching, all instructions must be done on the main thread.
    func preloadStatesList() async {
        let context = container.viewContext
        let statesFetch = USState.fetchRequest()
        statesFetch.sortDescriptors = [
            NSSortDescriptor(key: "stateName", ascending: true)
        ]
        
        let count = (try? context.count(for: statesFetch)) ?? 0
        guard count == 0 || count < 50 else {return}
        
        let defaultStates = USStateJSON.allStates
        
        // If, for whatever reason, the preloading method was terminated
        // before it could complete and there is less than 50 states but
        // more than 0 just create new USState objects for the remaining
        // ones.
        if count > 0 {
            let existingStates = (try? context.fetch(statesFetch)) ?? []
            let existingNames = Set<String>(existingStates.map(\.USStateName))
            let allNames = Set<String>(defaultStates.map(\.stateName))
            let newNames = allNames.subtracting(existingNames)
            
            let newStates = defaultStates.filter { state in
                newNames.contains(state.stateName)
            }
            
            for state in newStates {
                let item = USState(context: context)
                item.stateID = UUID()
                item.stateName = state.stateName
                item.USStateAbbreviation = state.abbreviation
                
            }//: LOOP
        } else {
            for state in defaultStates {
                let item = USState(context: context)
                item.stateID = UUID()
                item.stateName = state.stateName
                item.abbreviation = state.abbreviation
            }
        }//: IF ELSE
        save()
    }//: preloadStatesList()
    
    // MARK: Achievements (awards)
    /// Method for preloading Achievement CoreData entities based on the Awards.json file and
    /// Award struct.
    ///
    /// - Note: This method has logic that syncs the values of the Awards.json file with the CoreData entities by
    /// either adding or deleting Achievement objects as determined by the award name property for each Award object
    /// in the static allAwards array if the number of objects in that array is not equal to the number of fetched
    /// Achievement objects from CoreData.
    func preloadAllAchievements() async {
        let context = container.viewContext
        let achievementsFetch = Achievement.fetchRequest()
        achievementsFetch.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        let defaultAwards = Award.allAwards
        
        // Ensuring that context mutations occur on the main thread
        let count = await MainActor.run {
            (try? context.count(for: achievementsFetch)) ?? 0
        }
        // ONLY preload if there are either no Achievement entities OR
        // if the # of Achievement entities is not equal to the number
        // in the Award.allAwards array
        guard count == 0 || count != defaultAwards.count else {return}
        
        if count == 0 {
            for award in defaultAwards {
                let item = Achievement(context: context)
                item.id = UUID()
                item.name = award.name
                item.achievementDescript = award.description
                item.notificationText = award.notificationText
                item.criterion = award.criterion
                item.value = Int32(award.value)
                item.image = award.image
                item.color = award.color
            }//: LOOP
        } else {
            // Unable to run the fetch within the MainActor.run closure due to a warning
            // that NSManagedObjects cannot conform to Sendable, which is a requirement
            // for the closure.
            let existingAchievements = (try? context.fetch(achievementsFetch)) ?? []
            let existingNames = Set<String>(existingAchievements.map((\.achievementName)))
            let officialAwardList = Set<String>(defaultAwards.map(\.name))
            let addedAchievements = officialAwardList.subtracting(existingNames)
            let removedAchievements = existingNames.subtracting(officialAwardList)
            
            // If there are any achievements that are in the offical list but NOT
            // saved in CoreData, then create and save them.
            if addedAchievements.isNotEmpty {
                let achievementsToLoad: [Award] = defaultAwards.filter { addedAchievements.contains($0.name)
                }
                
                for achievement in achievementsToLoad {
                    let item = Achievement(context: context)
                    item.id = UUID()
                    item.name = achievement.name
                    item.achievementDescript = achievement.description
                    item.notificationText = achievement.notificationText
                    item.criterion = achievement.criterion
                    item.value = Int32(achievement.value)
                    item.image = achievement.image
                    item.color = achievement.color
                }//: LOOP
            }//: IF (addedAchievements.isNOTEmpty)
            
            // If there are any achievements that are NOT in the official list but
            // are saved in CoreData, then delete those objects
            if removedAchievements.isNotEmpty {
                let achievementsToDelete: [Award] = defaultAwards.filter { removedAchievements.contains($0.name)
                }
                
                for achievement in achievementsToDelete {
                    let matchingAchievement = existingAchievements.first {
                        $0.name == achievement.name
                    }
                    
                    if let foundAchievement = matchingAchievement {
                        delete(foundAchievement)
                    }//: IF LET
                }//: LOOP
            }//: IF (removedAchievements.isNOTEmpty)
            
        }//: IF - ELSE
        
        save()
    }//: preloadAllAchievements
    
    // MARK: - Set Settings Keys Defaults
    
    /// Method that creates an initial value for all of the keys stored in the @Published property
    /// sharedSettings (NSUbiquitiousKeyValueStore) so that all notifications are set to be
    /// turned on by default and reasonable values given for the timing for notifications so that they
    /// can be made prior to the user making changes in Settings.
    ///
    /// - Defaults:
    ///     - primaryNotificationDays: 60 (representing days)
    ///     - secondaryNotificationDays: 14 (representing days)
    ///     - showAllLiveEventAlerts: true
    ///     - firstLiveEventAlert: 120 (representing minutes)
    ///     - secondLiveEventAlert: 14 (representing minutes)
    ///     - showExpiringCesNotifications: true
    ///     - showRenewalEndingNotifications: true
    ///     - showRenewalLateFeeNotifications: true
    ///     - showDAINotifications: true
    ///     - showReinstatementAlerts: true
    ///
    ///- Important: This method must only be called once, when the app is first launched, so that
    ///any changes that the user makes from then on are preserved.  Any additional settings keys need
    ///to be added both to this method as well as to the settingsKeys array in handleKeyValueStoreChanges.
    ///
    /// The method has a built-in check to ensure that the app has just been launched via counting
    /// the number of CeActivity objects in storage.  There should be none on the first run.
    func setDefaultSettingsKeys() {
        // Ensure that the app is being run for the first time before taking
        // any action to set values for the various setting keys
        let activityFetch = CeActivity.fetchRequest()
        let count = (try? container.viewContext.count(for: activityFetch)) ?? 0
        let credFetch = Credential.fetchRequest()
        let credCount = (try? container.viewContext.count(for: credFetch)) ?? 0
        let renewFetch = RenewalPeriod.fetchRequest()
        let renewCount = (try? container.viewContext.count(for: renewFetch)) ?? 0
        let tagsFetch = Tag.fetchRequest()
        let tagsCount = (try? container.viewContext.count(for: tagsFetch)) ?? 0
        guard count == 0, credCount == 0, renewCount == 0, tagsCount == 0, purchaseStatus == PurchaseStatus.free.id else {
            return
        }
        
        // Setting default values for keys:
            primaryNotificationDays = Double(60)
            secondaryNotificationDays = Double(14)
            showAllLiveEventAlerts = true
            firstLiveEventAlert = Double (120)
            secondLiveEventAlert = Double(30)
            showExpiringCesNotifications = true
            showRenewalEndingNotifications = true
            showRenewalLateFeeNotifications = true
            showDAINotifications = true
            showReinstatementAlerts = true
            setTagBadgeCount(to: BadgeCountOption.allItems.rawValue)
        
    }//: setDefaultSettingsKeys()
    
    /// Method for determining whether the app is being run for the very first time or not
    /// - Returns: True if all conditions are met; otherwise, false
    ///
    /// The conditions for determining whether the app is being run for the first time include
    /// the following:
    ///     - 0 CeActivity objects in storage AND
    ///     - 0 Credential objects in storage AND
    ///     - 0 RenewalPeriod objects in storage AND
    ///     - 0 Tag objects in storage AND
    ///     - purchaseStatus = "free"
    ///
    /// If all five of the above conditions are met, then it is most likely that the user is launching
    /// the app for the very first time.  If they had been previously using the app but are now
    /// installing it on another device, then there should be some objects saved (but they may
    /// still be a free user as they can create a limited number of objects with that status).
    func isAppRunForFirstTime() -> Bool {
        // To enhance performance, only run the rest of this function
        // if the user is in free mode.  If they made a purchase then
        // they have completed onboarding and have at the very least
        // looked around within the app.
        guard purchaseStatus == PurchaseStatus.free.id else { return false }
        
        let context = container.viewContext
        // Conditions for determining for first run determination
        let activityFetch = CeActivity.fetchRequest()
        let credentialFetch = Credential.fetchRequest()
        let renewalFetch = RenewalPeriod.fetchRequest( )
        let tagFetch = Tag.fetchRequest( )
        let appStatus = purchaseStatus
        
        // CoreData object counts
        let activityCount = (try? context.count(for: activityFetch)) ?? 0
        let credentialCount = (try? context.count(for: credentialFetch)) ?? 0
        let renewalCount = (try? context.count(for: renewalFetch)) ?? 0
        let tagCount = (try? context.count(for: tagFetch)) ?? 0
        
        if appStatus == PurchaseStatus.free.id, activityCount == 0, credentialCount == 0, renewalCount == 0, tagCount == 0 {
            return true
        } else {
            return false
        }
        
    }//: isAppRunForFirstTime
    
}//: DataController

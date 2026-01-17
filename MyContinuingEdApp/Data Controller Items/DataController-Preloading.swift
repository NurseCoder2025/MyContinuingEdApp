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
            place.countryID = UUID() // Ensure unique identifier
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
    
    // MARK: State List
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
            item.stateID = UUID()
            item.stateName = state.stateName
            item.abbreviation = state.abbreviation
        }
        
        save()
    }
    
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
            tagBadgeCountOf = BadgeCountOption.allItems.rawValue
        
    }//: setDefaultSettingsKeys()
    
}//: DataController

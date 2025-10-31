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
    
    
}//: DataController

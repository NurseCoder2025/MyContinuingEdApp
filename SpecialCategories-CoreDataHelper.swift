//
//  SpecialCategories-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import Foundation


// Purpose: Creating computed properties to help with managing Core Data
// optionals and Preview

extension SpecialCategory {
    
    var specialName: String {
        get {name ?? ""}
        set {name = newValue}
    }
    
    var specialAbbreviation: String {
        get {abbreviation ?? ""}
        set {abbreviation = newValue}
    }
    
    var specialCatDescription: String {
        get {catDescription ?? ""}
        set {catDescription = newValue}
    }
}


// MARK: - Creating example category
extension SpecialCategory {
    
    static var example: SpecialCategory {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let sampleCat = SpecialCategory(context: context)
        sampleCat.name = "Category A"
        sampleCat.abbreviation = "Cat A"
        sampleCat.catDescription = "Ohio Nursing Laws & Rules"
        
        return sampleCat
    }
}

// Adding a computed property that will create an array of CeActivities for a given Special Category
extension SpecialCategory {
    
    var designatedActivities: [CeActivity] {
        let returnedItems = activities?.allObjects as? [CeActivity] ?? []
        return returnedItems.sorted {
            ($0.ceActivityAddedDate) < ($1.ceActivityAddedDate)
        }
    }
}


// MARK: - Special Category Computed Label Name
// This extension is to make it easier to populate UI elements with text
// for each object, as not all will have an abbreviation entered by the user.
extension SpecialCategory {
    var labelText: String {
        if specialAbbreviation == "" {
            return specialName
        } else {
            return specialAbbreviation
        }
    }
}

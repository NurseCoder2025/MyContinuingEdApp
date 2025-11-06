//
//  SpecialCatViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/4/25.
//

// Purpose: Refactoring UI so that logic is handled within a view controller to fit the
// MVVM pattern

import CoreData
import Foundation
import SwiftUI

extension SpecialCECatsManagementSheet {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Passing in a CeActivity object for which special categories will be assigned
        @Published var activity: CeActivity?
        
        // Passing in a Credential object for assigning special categories to
        @Published var credential: Credential?
        
        // Property for showing the SpecialCategorySheet for editing a category
        @Published var editSpecialCategory: Bool = false
        
        // Properties for holding a special category for editing or deleting purposes
        @Published var addedSpecialCategory: SpecialCategory?
        @Published var specialCatToEdit: SpecialCategory?
        @Published var specialCatToDelete: SpecialCategory?
        
        // Deletion alert property
        @Published var showDeleteWarning: Bool = false
        
        // MARK: - COMPUTED PROPERTIEs
        var sheetForString: String {
            if let passedInCredential = credential {
                return String("To: \(passedInCredential.credentialName)")
            } else if let passedInActivity = activity {
                return String("For: \(passedInActivity.ceTitle)")
            } else {
                return ""
            }
        }//: sheetForString
        
        
        // MARK: - FUNCTIONS
        
        /// Method for adding/removing a SpecialCategory from either a CeActivity or Credential object, depending on whether the
        /// SpecialCECatsManagamentSheet is being used within the context of a CeActivity (ActivityView) or Credential (CredentialSheet).
        /// The object parameter is a generic which can take any NSManaged object to minimize code duplication.
        /// - Parameters:
        ///   - category: SpecialCategory object passed in from the SpecialCECatsManagementSheet(SCECMS) List
        ///   - object: Either a CeActivity or Credential object, depending on the context of the SCECMS and what was passed
        ///   in to its intializer
        private func addRemoveSpecialCatFrom<T: NSManagedObject>(category: SpecialCategory, _ object: T) {
            // Adding or removing if passed in object was a Credential
            if object is Credential {
                if let passedInCred = object as? Credential {
                    if let credSpecCats = passedInCred.specialCats as? Set<SpecialCategory> {
                       var assigndCats = credSpecCats
                        if assigndCats.contains(category) {
                            assigndCats.remove(category)
                        } else {
                            assigndCats.insert(category)
                        }
                        
                        passedInCred.specialCats = NSSet(array: Array(assigndCats))
                        dataController.save()
                    }
                    
                }//: IF LET
            } else if object is CeActivity {
                if let passedInActivity = object as? CeActivity {
                    if passedInActivity.specialCat == category {
                        passedInActivity.specialCat = nil
                    } else {
                        passedInActivity.specialCat = category
                    }
                }
            }
            
        }//: addRemoveSpecialCatFrom(object)
        
        func addNewSpecialCategory() {
            let newSpecialCat = dataController.createNewSpecialCategory()
            addedSpecialCategory = newSpecialCat
        }//: addNewSpecialCategory
        
        /// Deletes the selected special CE category object once confirmed by the user
        func deleteSelectedCategory() {
            if let category = specialCatToDelete {
                dataController.delete(category)
            }
            dataController.save()
        }//: deleteSelectedCategory()
        
        
        /// Method that will return either all SpecialCategory objects that are assigned to the passed in credential object OR an array
        /// of SpecialCategory objects that haven't been assigned to a Credential yet.
        /// - Parameter credential: optional Credential object for which assigned SpecialCategories are to be returned
        /// - Returns: array of SpecialCategories that either have the assigned Credential or none at all
        func specialCatsAssignedTo(credential: Credential?) -> [SpecialCategory] {
            if credential == nil {
                let specialCatFetch = SpecialCategory.fetchRequest()
                specialCatFetch.sortDescriptors = [NSSortDescriptor(keyPath: \SpecialCategory.name, ascending: true)]
                
                let fetchedSpecialCats: [SpecialCategory] = (try? dataController.container.viewContext.fetch(specialCatFetch)) ?? []
                
                var allUnassignedSpecialCats: [SpecialCategory] = []
                for cat in fetchedSpecialCats {
                    if cat.credential == nil {
                        allUnassignedSpecialCats.append(cat)
                    }
                }//: LOOP
                
                return allUnassignedSpecialCats
                
            } else {
                if let credSpecCats = credential?.specialCats as? Set<SpecialCategory> {
                    return Array(credSpecCats)
                }
                return []
            }
            
        }//: specialCatsAssignedTo(credential)
        
        
        /// Method that handles the adding and removing of SpecialCategory objects from Credential and CeActivity objects
        /// - Parameter category: SpecialCategory to add or remove
        func tapToAddOrRemove(category: SpecialCategory) {
            if let passedInCred = credential {
                addRemoveSpecialCatFrom(category: category, passedInCred)
            } else if let passedInActivity = activity {
                addRemoveSpecialCatFrom(category: category, passedInActivity)
            }
        }//: tapToAddOrRemove()
        
        
        // MARK: - INIT
        init(dataController: DataController, cred: Credential? = nil, activity: CeActivity? = nil, ) {
            self.dataController = dataController
            self.credential = cred
            self.activity = activity
        }//: INIT
        
    }//: VIEW MODEL
    
}//: SpecialCECatsManagementSheet

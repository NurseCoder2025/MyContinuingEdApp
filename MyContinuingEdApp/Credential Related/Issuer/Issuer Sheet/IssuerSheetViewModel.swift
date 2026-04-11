//
//  IssuerSheetViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation


extension IssuerSheet {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // MARK: - CORE DATA
        private let countriesController: NSFetchedResultsController<Country>
        private let statesController: NSFetchedResultsController<USState>
        
        @Published var allCountries: [Country] = []
        @Published var allStates: [USState] = []
        
        // MARK: - FUNCTIONS
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if controller == countriesController {
                if let newCountries = controller.fetchedObjects as? [Country] {
                    allCountries = newCountries
                }//: IF LET
            } else if controller == statesController {
                if let newStates = controller.fetchedObjects as? [USState] {
                    allStates = newStates
                }
            }
        }//: controllerDidChangeContent
        
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            // Countries fetch
            let countryFetch = Country.fetchRequest()
            countryFetch.sortDescriptors = [
                NSSortDescriptor(keyPath: \Country.sortOrder, ascending: true),
                NSSortDescriptor(keyPath: \Country.name, ascending: true)
            ]
            
            countriesController = NSFetchedResultsController(
                fetchRequest: countryFetch,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            // US States fetch
            let statesFetch = USState.fetchRequest()
            statesFetch.sortDescriptors = [
                NSSortDescriptor(keyPath: \USState.stateName, ascending: true)
            ]
            
            statesController = NSFetchedResultsController(
                fetchRequest: statesFetch,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            super.init()
            countriesController.delegate = self
            statesController.delegate = self
            
            do {
                try countriesController.performFetch()
                allCountries = countriesController.fetchedObjects ?? []
            } catch  {
                print("Unable to fetch any country objects...")
            }
            
            do {
                try statesController.performFetch()
                allStates = statesController.fetchedObjects ?? []
            } catch  {
                print("Unable to fetch any state objects...")
            }
            
        }//: INIT
        
    }//: VIEW MODEL
    
}//: IssuerSheet

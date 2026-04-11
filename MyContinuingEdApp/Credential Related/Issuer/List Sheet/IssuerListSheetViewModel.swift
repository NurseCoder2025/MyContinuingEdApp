//
//  IssuerListSheetViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation
import UIKit


extension IssuerListSheet {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Property related to the selection of an issuer object
        @Published var selectedIssuer: Issuer?
        
        // Property for storing a newly created Issuer
        @Published var newIssuer: Issuer?
        
        // Property for editing an existing Issuer
        @Published var issuerToEdit: Issuer?
        
        // Property for adding a new issuer
        @Published var showIssuerSheet: Bool = false
        
        // Properties for deleting an issuer
        @Published var showDeletionWarning: Bool = false
        
        // MARK: - CORE DATA
       let issuersController: NSFetchedResultsController<Issuer>
       @Published var allIssuers: [Issuer] = []
        
        // MARK: - FUNCTIONS
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if let retrievedIssuers = controller.fetchedObjects as? [Issuer] {
                allIssuers = retrievedIssuers
            }
        }//: controllerDidChangeContent
        
        /// Upon a user tapping the IssuerRowView button in IssuerListSheet, the specific Issuer tapped on will be
        /// assigned to the selectedIssuer property as well as to whatever Credential was passed in as the issuer property value
        /// - Parameters:
        ///   - someIssuer: Issuer object from the list of allIssuers
        ///   - someCred: Credential object passed in to IssuerListSheet
        func tapSelectsAndAssignsIssuer(someIssuer: Issuer, someCred: Credential) {
            selectedIssuer = someIssuer
            someCred.issuer = someIssuer
        }
        
        
        /// Function called when the user swipes to edit an Issuer object from the IssuerListSheet.  Assigns a passed in Issuer
        /// object to the publisehd selectedIssuer property and toggles the showIssuerSheet which will pop up with data from the
        /// selected Issuer so the user can edit it.
        /// - Parameter someIssuer: an Issuer object passed in after the user swipes to edit in IssuerListSheet
        func editSelectedIssuer(_ someIssuer: Issuer) {
            issuerToEdit = someIssuer
        }
        
        /// Method adds a temporary Issuer object to the view context so the user can then edit it as
        /// desired.  Do not use the dataController's createNewIssuer method here because it will
        /// save the new Issuer object to persistent storage and that will cause issues with UI updating
        /// (the sheet with the new Issuer will not be shown until the view is dismissed and brought up again).
        func addNewIssuer() {
            let context = dataController.container.viewContext
            let issuerToAdd = Issuer(context: context)
            issuerToAdd.issuerID = UUID()
            issuerToAdd.issuerName = "New Issuer"
            
            // Set default country to United States
            let countryRequest: NSFetchRequest<Country> = Country.fetchRequest()
            countryRequest.predicate = NSPredicate(format: "alpha3 == %@", "USA")
            
            let defaultCountry = (try? context.fetch(countryRequest).first) ?? nil
            issuerToAdd.country = defaultCountry
            
            newIssuer = issuerToAdd
        }
        
        func deleteIssuer(_ issuer: Issuer) {
            selectedIssuer = issuer
            showDeletionWarning = true
            
            if showDeletionWarning {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }//: deleteIssuer()
        
        /// Deletes the swipped issuer object from the viewContext and, if saved, persistent
        /// storage.
        func confirmedDeleteIssuer() {
            if let unwantedIssuer = selectedIssuer {
                dataController.delete(unwantedIssuer)
                dataController.save()
            }
            
            selectedIssuer = nil
            showDeletionWarning = false
        } //: confirmed delete function
        
        func cancelIssuerDelete() {
            selectedIssuer = nil
            showDeletionWarning = false
        }
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            // Issuer fetch request and controller setup
            let issuersFetch = Issuer.fetchRequest()
            issuersFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Issuer.issuerName, ascending: true)]
            
            issuersController = NSFetchedResultsController(
                fetchRequest: issuersFetch,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            super.init()
            do {
                try issuersController.performFetch()
                allIssuers = issuersController.fetchedObjects ?? []
            } catch {
                print("Unable to fetch any Issuer objects")
            }
            
            
        }//: INIT
        
    }//: VIEW MODEL
    
}//: EXT IssuerListSheet

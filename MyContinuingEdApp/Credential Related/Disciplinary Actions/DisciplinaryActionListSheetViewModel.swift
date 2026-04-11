//
//  DisciplinaryActionListSheetViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation
import UIKit


extension DisciplinaryActionListSheet {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        let credential: Credential
        
        // For adding a new DAI (Disciplinary Action Item)
        @Published var addNewDAI: Bool = false
        @Published var newDAI: DisciplinaryActionItem?
        
        // For editing an existing DAI
        @Published var daiTOEdit: DisciplinaryActionItem?
        
        // For deleting an existing DAI
        @Published var daiToDelete: DisciplinaryActionItem?
        @Published var showDeletionWarning: Bool = false
        
        // MARK: - CORE DATA
        let daiController: NSFetchedResultsController<DisciplinaryActionItem>
        @Published var allDAIs: [DisciplinaryActionItem] = []
        
        // MARK: - FUNCTIONS
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if let newDAIs = daiController.fetchedObjects {
                allDAIs = newDAIs
            }
        }//: controllerDidChangeContent
        
        /// Function that handles the creation of new DisciplinaryActionItem objects by calling the appropriate data controller
        /// method and then toggling the addNewDAI Boolean which will trigger a sheet in the list view.
        func addNewDAIObject() {
            newDAI = dataController.createNewDAI(for: credential)
            addNewDAI = true
        }
        
        
        /// Function which triggers the presentation of the DisciplinaryActionItem sheet with an existing object by assigning a
        /// selected (passed in) DAI object to the daiToEdit published property.
        /// - Parameter someDAI: DisciplinaryActionItem object tthat will be presented to the user for editing
        func editExistingDAI(someDAI: DisciplinaryActionItem) {
            daiTOEdit = someDAI
        }
        
        
        /// Function that assigns a particular DisciplinaryActionItem to the daiToDelete property whenever the user swipes on the
        /// delete button in DisciplinaryActionListSheet, triggers a haptic warning as well as the showDeletionWarning boolean. The
        /// confirmedDeleteDAI() method will do the actual deleting should the user confirm the action in the alert popup.
        /// - Parameter someDAI: DisciplinaryActionItem object that the user swipes on to delete
        func deleteDAI(someDAI: DisciplinaryActionItem) {
            daiToDelete = someDAI
            showDeletionWarning = true
            
            if showDeletionWarning {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
        }//: deleteDAI(someDAI)
        
        func confirmedDeleteDAI() {
            if let selectedDAI = daiToDelete {
                dataController.delete(selectedDAI)
            }
            
            dataController.save()
        }
        
        // MARK: - INIT
        init(dataController: DataController, credential: Credential) {
            self.dataController = dataController
            self.credential = credential
            
            // Fetching DAIs, but only those that apply to a specific Credential object
            // (whichever Credential the user is currently editing)
            let daiRequest = DisciplinaryActionItem.fetchRequest()
                daiRequest.predicate = NSPredicate(format: "credential == %@", credential)
                daiRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionStartDate, ascending: true)]
            
            daiController = NSFetchedResultsController(
                fetchRequest: daiRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            super.init()
            daiController.delegate = self
            
            do {
                try daiController.performFetch()
                allDAIs = daiController.fetchedObjects ?? []
            } catch {
                print("Unable to fetch all DAI objects")
            }
            
        }//: INIT
        
        
    }//: VIEW MODEL
    
}//: EXT DisciplinaryActionListSheet

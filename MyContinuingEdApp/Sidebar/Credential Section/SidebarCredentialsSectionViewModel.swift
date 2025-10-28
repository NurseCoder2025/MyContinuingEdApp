//
//  SidebarCredentialsSectionViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/23/25.
//

import CoreData
import Foundation

extension SidebarCredentialsSectionView {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Deleting renewal periods
        @Published var showDeletingRenewalAlert: Bool = false
        @Published var renewalToDelete: RenewalPeriod?
        
        // Credential for adding a new renewal period
        @Published var credForRenewal: Credential?
        
        // Converting all fetched renewal periods to Filter objects
        var convertedRenewalFilters: [Filter] {
            renewals.map { renewal in
                Filter(
                    name: renewal.renewalPeriodName,
                    icon: "timer.square",
                    renewalPeriod: renewal,
                    credential: renewal.credential
                )
            }
        }//: convertedRenewalFilters
        
        // MARK: - CORE DATA
        private let credentialsController: NSFetchedResultsController<Credential>
        @Published var allCredentials: [Credential] = []
        
        private let renewalsController: NSFetchedResultsController<RenewalPeriod>
        @Published var renewals: [RenewalPeriod] = []
        
        // MARK: - FUNCTIONS
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if let newCreds = controller.fetchedObjects as? [Credential] {
                allCredentials = newCreds
            }
            
            if let newRenewals = controller.fetchedObjects as? [RenewalPeriod] {
                renewals = newRenewals
            }
            
        }//: controllerDidChangeContent
        
        
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            let context = dataController.container.viewContext
            
            // Configuring Core Data controllers & fetch requests
            // MARK: Credential objects
            let credRequest = Credential.fetchRequest()
            credRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Credential.name, ascending: true)]
            
            credentialsController = NSFetchedResultsController(
                fetchRequest: credRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            
            do {
                try credentialsController.performFetch()
                allCredentials = credentialsController.fetchedObjects ?? []
            } catch {
                print("Failed to load any credential objects from the view context")
            }
            
            
            // MARK: Renewal objects
            let renewalRequest = RenewalPeriod.fetchRequest()
            renewalRequest.sortDescriptors = [NSSortDescriptor(keyPath: \RenewalPeriod.periodName, ascending: true)]
            
            renewalsController = NSFetchedResultsController(
                fetchRequest: renewalRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            do {
                try renewalsController.performFetch( )
                renewals = renewalsController.fetchedObjects ?? []
            } catch  {
                print("Failed to load renewal period objects from the view context.")
            }
            
            // Assigning delegate to both controllers
            super.init()
            credentialsController.delegate = self
            renewalsController.delegate = self
            
        }//: INIT
        
    }//: VIEW MODEL
    
    
    
}//: SidebarCredentialsSectionView (ext)

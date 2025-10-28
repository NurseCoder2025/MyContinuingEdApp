//
//  CredentialSubCatListSheetViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation

extension CredentialSubCatListSheet {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Property for storing a selected Credential from the list
        @Published var selectedCredential: Credential?
        
        // Property for storing a Credential to edit
        @Published var credentialToEdit: Credential?
        
        // Alert properties for deleting a credential object
        @Published var showDeleteAlert: Bool = false
        
        // Property for adding a new Credential object
        @Published var showCredentialSheet: Bool = false

        // The singular, lowercased, string value from the CredentialType enum is passed in here
        let credentialType: String
        
        // MARK: - COMPUTED PROPERTIES
        /// Computed property that returns an array of all Credential objects that match
        /// the passed-in credentialType string.  Sorted by name.
        var credentialsOfType: [Credential] {
            let fetchRequest: NSFetchRequest<Credential> = Credential.fetchRequest()
            
            // IF a specific type of credential is being requested, filter by that type
            if credentialType != "all" {
                fetchRequest.predicate = NSPredicate(format: "credentialType == %@", credentialType)
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let context = dataController.container.viewContext
            let creds = (try? context.fetch(fetchRequest)) ?? []
            
            return creds
        }
        
        
        /// Computed property which returns a dictionary of credentials grouped by the first letter of their name
        var alphabeticalCredentialGroupings: [String: [Credential]] {
            Dictionary(grouping: credentialsOfType) { cred in
                String(cred.credentialName.prefix(1).uppercased())
            }
        }
        
        /// Creates an array of all first letters of the credential names for section headers
        var sortedSectionKeys: [String] {
            alphabeticalCredentialGroupings.keys.sorted()
        }
        
        // MARK: - FUNCTIONS
        func deleteCredential(_ credential: Credential) {
            let context = dataController.container.viewContext
            context.delete(credential)
            try? context.save()
            selectedCredential = nil
        }
        
        // MARK: - INIT
        init(dataController: DataController, credType: String) {
            self.dataController = dataController
            self.credentialType = credType
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: CredentialSubCAtListSheet EXT


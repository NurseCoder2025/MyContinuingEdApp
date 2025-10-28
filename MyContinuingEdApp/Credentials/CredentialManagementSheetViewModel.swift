//
//  CredentialManagementSheetViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation



extension CredentialManagementSheet {
    
    class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Property to pull up the CredentialSheet for adding a new credential
        @Published var showAddCredentialSheet: Bool = false
        
        // Property to store a newly created Credential object
        @Published var newCredential: Credential?
        
        // Property to show the CredentialSubCatListSheet as a pop-up
        @Published var showCredSubCatListSheet: Bool = false
        
        // Property to hold the selected credential subcategory
        @Published var selectedCat: CredentialCatWrapper? = nil
        
        // MARK: - COMPUTED PROPERTIES
       
    
        /// Returning any encumbered credentials as determined by the getEncumberedCredentials() method
        /// in the Data Controller class.  Will be used to determine whether to show a navigation link to the
        /// EncumberedCredentialListSheet or not.
        var encumberedCreds: [Credential] {
            dataController.getEncumberedCredentials()
        }
        
        // MARK: - FUNCTIONS
        
        /// Function takes in a String which represents one of the CategoryType enum raw values (see Enums-General file for details)
        /// and calls the data controller's getNumberOfCredTypes method on that string to return an integer value from the fetch request
        /// that the method uses.
        /// - Parameter category: String value representing one of the CategoryType raw values
        /// - Returns: Number of Credential objects with that matching category value
        func getCatBadgeCount(category: String) -> Int {
            let count = dataController.getNumberOfCredTypes(type: category)
            return count
        }
        
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: EXT

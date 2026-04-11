//
//  SidebarCredentialsSectionHeaderViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/23/25.
//

import Foundation
import SwiftUI


extension SidebarCredentialSectionHeader {
    
    class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        @ObservedObject var credential: Credential
        
        // Property to hold the credential which the user wants to edit
        @Published var selectedCredential: Credential?  // needed for DEBUG function
        @Published var credentialToEdit: Credential?
        
        // MARK: - FUNCTIONS
        
        
        // MARK: - INIT
        init(dataController: DataController, credential: Credential) {
            self.dataController = dataController
            self.credential = credential
        }//: INIT

    }//: VIEW MODEL
    
}//: SidebarCredentialSectionHeader

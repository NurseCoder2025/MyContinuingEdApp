//
//  SidebarViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/23/25.
//

import CoreData
import Foundation


extension SidebarView {
    
    class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Holder property for creating a new Credential
        @Published var newlyCreatedCredential: Credential?
        
        // Properties for renaming tags
        @Published var showRenamingAlert: Bool = false
        @Published var newTagName: String = ""
        @Published var tagToRename: Tag?
        @Published var tagFilter: Filter?
        
        // Properties for editing renewal periods
        @Published var renewalSheetData: RenewalSheetData?
        
        // Property for holding a renewal period that the user wants to check progress on
        @Published var selectedRenewalForProgressCheck: RenewalPeriod?
        
    
        // Properties for deleting renewal periods
        @Published var showDeleteRenewalWarning: Bool = false
        @Published var renewalToDelete: RenewalPeriod?
        
        // MARK: - FUNCTIONS
        
        /// Changes the name of a user-created tag by assignig a new string value for a placeholder for the  tag's name property.
        /// This function does not save the change, however.  Instead, it toggles the showRenamingAlert @State property which triggers
        /// the alert box to pop up to ask for user confirmation before changing the tag's name property and then saving the change to disk.
        /// - Parameter selectedFilter: Tag object passed in as a Filter for renaming
        func renameTag(_ selectedFilter: Filter) {
            tagToRename = selectedFilter.tag
            newTagName = selectedFilter.name
        }
        
        /// When called, this method assigns a String value that the user typed in an alert box (presented when showRenamingAlert is
        ///  toggled to true) to the selected tag's name property then saves the change to persistent storage.
        func confirmTagRename() {
            tagToRename?.tagName = newTagName
            dataController.save()
        }
        
        /// Function called by the showDeleteRenewalWarning alert that will permanently delete the selected renewal period object from
        /// persistent storage.  As the alert message indicates, this will only delete the renewal period and not the credential or any associated
        /// CE activities with that renewal period.
        func deleteRenewalPeriod() {
            if let unwantedRenewal = renewalToDelete {
                dataController.delete(unwantedRenewal)
                dataController.save()
            }
        }//: deleteRenewalPeriod
        
        // MARK: - INITIALIZER
        init(dataController: DataController) {
            self.dataController = dataController
        }//: INIT
        
    }//: ViewModel
    
}//: SidebarView (ext)

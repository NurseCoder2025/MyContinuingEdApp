//
//  SidebarView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI

// The primary (initial) view when first launching the app. Provides different ways of filtering
// CE activities that have been entered: via 2 "smart" filters, user-created tags, and by
// credential-renewal cycle.

struct SidebarView: View {
    // MARK: - PROPERTIES
    // Accessing the data controller environmental object
    @EnvironmentObject var dataController: DataController
    
    // Properties for renaming tags
    @State private var showRenamingAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var tagToRename: Tag?
    @State private var tagFilter: Filter?
    
    // Properties for editing renewal periods
    @State private var renewalSheetData: RenewalSheetData?
    
    // Properties for deleting renewal periods
    @State private var showDeleteRenewalWarning: Bool = false
    @State private var renewalToDelete: RenewalPeriod?
    
    // MARK: - FILTERS
    // Defining smart filters
    let smartFilters: [Filter] = [.allActivities, .recentActivities]
   
    // MARK: - BODY
    var body: some View {
            List(selection: $dataController.selectedFilter) {
                // MARK: - SMART FILTERS SECTION
                Section("Smart Filters") {
                    ForEach(smartFilters, content: SidebarSmartFilterRow.init)
                } //: SECTION (smart filters)
                
                // MARK: - TAGS SECTION
                SidebarTagsSectionView(
                    onRenameTag: { filter in
                        tagFilter = filter
                        tagToRename = filter.tag
                        newTagName = filter.name
                        showRenamingAlert = true
                    }
                )
                // MARK: - CREDENTIALS SECTION
                SidebarCredentialsSectionView(
                    onEditRenewal: { cred, renewal in
                        renewalSheetData = RenewalSheetData(credential: cred, renewal: renewal)
                    },
                    onRenewalDelete: { renewal in
                        renewalToDelete = renewal
                        showDeleteRenewalWarning = true
                    },
                    onAddRenewal: { cred in
                        renewalSheetData = RenewalSheetData(credential: cred, renewal: nil)
                    }
                )
            } //: LIST
            .navigationTitle("CE Filters")
            // MARK: - Toolbar
            .toolbar(content: SidebarViewTopToolbar.init)
        // MARK: - Alerts
        // RENAMING TAG ALERT
        .alert("Rename Tag", isPresented: $showRenamingAlert) {
            Button("OK", action: { confirmTagRename() })
            Button("Cancel", role: .cancel) {}
            TextField("New tag name:", text: $newTagName)
        } //: ALERT
        
        // Deleting renewal period alert
        .alert("Delete Renewal Period?", isPresented: $showDeleteRenewalWarning) {
            Button("OK", action: {deleteRenewalPeriod()})
            Button("Cancel", role: .cancel) {}
        } message:  {
            Text("Deleting the \(renewalToDelete?.renewalPeriodName ?? "renewal period") will NOT delete any associated CE activities or credentials, but may impact renewal reminders and alerts. Are you sure you wish to delete it? ")
        }//: ALERT
        
        
        // MARK: - SHEETS
        .sheet(item: $renewalSheetData) { data in
            RenewalPeriodView(renewalCredential: data.credential, renewalPeriod: data.renewal)
        }
        
    } //: BODY
    
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
 
        
} //: STRUCT

// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(DataController.preview)
    }
}

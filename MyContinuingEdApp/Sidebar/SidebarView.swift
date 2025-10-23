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
    @StateObject private var viewModel: ViewModel
    
    // MARK: Smart filters
    let smartFilters: [Filter] = [.allActivities, .recentActivities]
   
    // MARK: - BODY
    var body: some View {
        List(selection: $viewModel.dataController.selectedFilter) {
                // MARK: - SMART FILTERS SECTION
                Section("Smart Filters") {
                    ForEach(smartFilters, content: SidebarSmartFilterRow.init)
                } //: SECTION (smart filters)
                
                // MARK: - TAGS SECTION
                SidebarTagsSectionView(
                    dataController: viewModel.dataController,
                    onRenameTag: { filter in
                        viewModel.tagFilter = filter
                        viewModel.tagToRename = filter.tag
                        viewModel.newTagName = filter.name
                        viewModel.showRenamingAlert = true
                    }
                )
                // MARK: - CREDENTIALS SECTION
                SidebarCredentialsSectionView(
                    dataController: viewModel.dataController,
                    onEditRenewal: { cred, renewal in
                        viewModel.renewalSheetData = RenewalSheetData(credential: cred, renewal: renewal)
                    },
                    onAddRenewal: { cred in
                        viewModel.renewalSheetData = RenewalSheetData(credential: cred, renewal: nil)
                    },
                    onRenewalDelete: { renewal in
                        viewModel.renewalToDelete = renewal
                        viewModel.showDeleteRenewalWarning = true
                    }
                    
                )
            } //: LIST
            .navigationTitle("CE Filters")
            // MARK: - Toolbar
            .toolbar(content: SidebarViewTopToolbar.init)
        
        // MARK: - Alerts
        // RENAMING TAG ALERT
            .alert("Rename Tag", isPresented: $viewModel.showRenamingAlert) {
                Button("OK", action: { viewModel.confirmTagRename() })
            Button("Cancel", role: .cancel) {}
                TextField("New tag name:", text: $viewModel.newTagName)
        } //: ALERT
        
        // Deleting renewal period alert
            .alert("Delete Renewal Period?", isPresented: $viewModel.showDeleteRenewalWarning) {
                Button("OK", action: {viewModel.deleteRenewalPeriod()})
            Button("Cancel", role: .cancel) {}
        } message:  {
            Text("Deleting the \(viewModel.renewalToDelete?.renewalPeriodName ?? "renewal period") will NOT delete any associated CE activities or credentials, but may impact renewal reminders and alerts. Are you sure you wish to delete it? ")
        }//: ALERT
        
        
        // MARK: - SHEETS
        .sheet(item: $viewModel.renewalSheetData) { data in
            RenewalPeriodView(renewalCredential: data.credential, renewalPeriod: data.renewal)
        }//: SHEET
        
    } //: BODY
    
    
 // MARK: - INIT
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
        
} //: STRUCT

// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(dataController: .preview)
           
    }
}

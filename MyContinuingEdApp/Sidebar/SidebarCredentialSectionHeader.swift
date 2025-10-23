//
//  SidebarCredentialSectionHeader.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//

// Purpose: To encapsulate funcationality related to editing a credential listed in the SidebarView as well as any
// RenewalPeriod objects.

import SwiftUI

struct SidebarCredentialSectionHeader: View {
    // MARK: - PROPERTIES
    @StateObject private var viewModel: ViewModel
        
    // Closure for adding a new renewal period
    var addNewRenewal: (Credential) -> Void
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text("\(viewModel.credential.credentialName) Renewals")
            Spacer()
            
            // MARK: Edit Credential button
            Button {
                viewModel.credentialToEdit = viewModel.credential
            } label: {
                Label("Edit Credential", systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }//: BUTTON
            
            // MARK: Add Renewal Period button
            Button {
                addNewRenewal(viewModel.credential)
            }label: {
                Label("Add Renewal Period", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            
            #if DEBUG
            // Debugging button
            Button {
                diagnoseRenewalNotShowing(
                    dataController: viewModel.dataController,
                    for: viewModel.selectedCredential
                )
            } label: {
                Label("Dx", systemImage: "sparkle.magnifyingglass")
                    .labelStyle(.iconOnly)
            }
            #endif
            
        }//: HSTACK
        // MARK: - SHEETS
        
        // Credential sheet for editing credential
        .sheet(item: $viewModel.credentialToEdit) { cred in
            CredentialSheet(credential: cred)
        }//: SHEET
        
       
        
    }//: BODY
    
    // MARK: - INIT
    init(dataController: DataController, credential: Credential, addNewRenewal: @escaping (Credential) -> Void) {
        let viewModel = ViewModel(dataController: dataController, credential: credential)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.addNewRenewal = addNewRenewal
    }//: INIT
    
}//: STRUCT


// MARK: - PREVIEW


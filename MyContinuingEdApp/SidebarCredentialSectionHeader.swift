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
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var credential: Credential
    
    // Property to hold the credential which the user wants to edit
    @State private var selectedCredential: Credential?  // needed for DEBUG function
    @State private var credentialToEdit: Credential?
        
    // Closure for adding a new renewal period
    var addNewRenewal: (Credential) -> Void
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text("\(credential.credentialName) Renewals")
            Spacer()
            
            // MARK: Edit Credential button
            Button {
                credentialToEdit = credential
            } label: {
                Label("Edit Credential", systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }//: BUTTON
            
            // MARK: Add Renewal Period button
            Button {
                addNewRenewal(credential)
            }label: {
                Label("Add Renewal Period", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            
            #if DEBUG
            // Debugging button
            Button {
                diagnoseRenewalNotShowing(dataController: dataController, for: selectedCredential)
            } label: {
                Label("Dx", systemImage: "sparkle.magnifyingglass")
                    .labelStyle(.iconOnly)
            }
            #endif
            
        }//: HSTACK
        // MARK: - SHEETS
        
        // Credential sheet for editing credential
        .sheet(item: $credentialToEdit) { cred in
            CredentialSheet(credential: cred)
        }//: SHEET
        
       
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW


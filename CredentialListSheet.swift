//
//  CredentialListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/9/25.
//

import CoreData
import SwiftUI


// The purpose of this file is to create a sheet that will appear with all entered credentials.
// From this sheet, the user can add, edit, or delete credentials as desired.

// ** IMPORTANT NOTE **
// The data model for this app is setup so that deleting a Credential will
// delete all RenewalPeriod and CeActivity objects
// that are connected with it!

struct CredentialListSheet: View {
    // MARK: - PROPERTIES
    // Environment Properties
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // MARK: Adding/editing Credential objects properties
    @State private var showCredentialSheet: Bool = false
    @State private var credentialToDelete: Credential?
    @State private var credentialToEdit: Credential?
    
    // MARK: Warnings & Alerts
    @State private var showDeletionWarning: Bool = false
    
    
    // MARK: - CORE DATA Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            List {
                ForEach(allCredentials) { credential in
                    Button {
                        credentialToEdit = credential
                    } label: {
                        HStack {
                            Text(credential.credentialName)
                            Spacer()
                            if credential == credentialToEdit {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }//: HSTACK
                    }
                }//: LOOP
                .onDelete(perform: deleteCredential)
                
            }//: LIST
            .navigationTitle("Manage Credentials")
            .swipeActions {
                Button {
                    CredentialSheet(credential: credentialToEdit)
                } label: {
                    Label("Edit Credential", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                        
                }
            }//: SWIPE
            
            
        }//: NAV VIEW
    }
    
    // MARK: - Functions
    func deleteCredential(_ indices: IndexSet) {
        for item in indices {
            let selectedCred = allCredentials[item]
            credentialToDelete = selectedCred
        }
        showDeletionWarning = true
    }//: deleteCredential
}

// MARK: - PREVIEW
#Preview {
    CredentialListSheet()
}

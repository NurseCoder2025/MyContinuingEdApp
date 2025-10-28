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
            List(allCredentials) { credential in
                HStack {
                    Text(credential.credentialName)
                }//: HSTACK
                .swipeActions {
                    // Edit Credential
                    Button {
                        credentialToEdit = credential
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    // Delete Credential
                    Button(role: .destructive) {
                        credentialToDelete = credential
                        showDeletionWarning = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                }//: SWIPE ACTIONS
                
            }//: LIST
            .navigationTitle("Manage Credentials")
            
            // MARK: - SHEETS
            .sheet(item: $credentialToEdit) { credential in
                CredentialSheet(credential: credential)
            }
            
            // MARK: - ALERTS
            .alert("Confirm Credential Deletion", isPresented: $showDeletionWarning) {
                Button("Delete", action: {deleteCredential()})
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You are about to delete \(credentialToDelete?.credentialName ?? "the selected credential").  Are you sure? This cannot be undone.")
            }//: ALERT (delete)
            
            // MARK: - ON APPEAR
            .onAppear {
                credentialToEdit = nil
                credentialToDelete = nil
            }
            
        }//: NAV VIEW
    }
    
    // MARK: - Functions
    func deleteCredential() {
        if let selectedCredential = credentialToDelete {
            dataController.delete(selectedCredential)
            dataController.save()
        }
    }//: deleteCredential
}

// MARK: - PREVIEW
#Preview {
    CredentialListSheet()
}

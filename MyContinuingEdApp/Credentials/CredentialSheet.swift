//
//  LicenseSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/28/25.
//

import CoreData
import SwiftUI

// Purpose: To serve as the holding screen for various UI controls whereby
// the user adds or edits credential objects

// 10/13/25 update: changed credential property from optional let property to @ObservedObject non-optional in order
// to help address major bug with Issuer country and state selection properties not being saved upon change.

struct CredentialSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Existing credential object being passed in for editing
    @ObservedObject var credential: Credential
    
    // Show an alert if a credential type has not been selected by the user
    @State private var showNoCredTypeAlert: Bool = false
    
    @State private var showDeleteCredAlert: Bool = false
    
    // MARK: - BODY
    var body: some View {
    
        // MARK: - Main Nav VIEW
        NavigationView {
            Form {
                // MARK: BASIC INFO
                BasicCredentialInfoView(credential: credential)
                
                
                // MARK: ACTIVE Y or N?
                ActiveCredentialSectionView(credential: credential)
                
                // MARK: Issue & Renewal Section
                CredentialIssueAndRenewalSectionView(credential: credential)
                   
                
                // MARK: Next Expiration
                // Will be shown to the user ONLY if editing an existing credential
                CredentialNextExpirationSectionView(credential: credential)
                    
                
               // MARK: Disciplinary Actions
               CredentialDAISectionView(credential: credential)
                
                
                // MARK: RESTRICTIONS
                CredentialRestrictionsSectionView(credential: credential)
                
                // MARK: Delete Button
                DeleteObjectButtonView(buttonText: "Delete Credential") {
                    showDeleteCredAlert = true
                }
                   
                
            }//: FORM
        // MARK: - NAV TITLE
            .navigationTitle(credential.credentialName == "New Credential" ? "Create Credential" : "Credential Info")
           
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {dismiss()}){
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                    }
                }//: TOOLBAR ITEM
                    
                
            }//: TOOLBAR
            // MARK: - ALERTS
            .alert("Need Credential Type", isPresented: $showNoCredTypeAlert) {
                Button("OK") {}
            } message: {
                Text("Unable to save credential since no credential type has been selected.  Please select a credential type and try saving again.")
            }//: ALERT
            
            .alert("Delete Credential?", isPresented: $showDeleteCredAlert) {
                Button("OK", role: .destructive) {
                    dataController.delete(credential)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete the current credential? This will delete any associated disciplinary actions and renewal periods. However, activities associated with this credential will NOT be deleted.")
            }//: ALERT
                
            // MARK: - ON RECEIVE
            .onReceive(credential.objectWillChange) { _ in
                dataController.queueSave()
            }//: ON RECEIVE
            
            .onSubmit {dataController.save()}
            // MARK: - ON DISAPPEAR
            .onDisappear {
                // If the user dismisses the sheet without updating the
                // name of the credential, then it is assumed that
                // they don't want to actually create a credential
                if credential.credentialName == "New Credential" {
                    dataController.delete(credential)
                }
            }// ON DISAPPEAR
        }//: NAV VIEW
    }//: BODY
    
    // MARK: - METHODS
    
    /// This function first maps the UI control fields to either an existing Credential object or new Credential object,
    /// then saves the changes to Core Data.
    func saveChanges() {
        dataController.save()
        dismiss()
    }//: MAP & SAVE
    
}

 // MARK: - PREVIEW
#Preview {
    CredentialSheet(credential: .example)
        .environmentObject(DataController(inMemory: true))
}

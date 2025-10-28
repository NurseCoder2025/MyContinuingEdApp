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
    
    // MARK: - COMPUTED PROPERTIES
    var allDAIs: [DisciplinaryActionItem] {
        // Create empty array to hold results
        var actions: [DisciplinaryActionItem] = []
            
        // Create fetch request and sort by action name
            let request = DisciplinaryActionItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionName, ascending: true)]
            request.predicate = NSPredicate(format: "credential == %@", credential)
            actions = (try? dataController.container.viewContext.fetch(request)) ?? []
        
        return actions
    }
    
  
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
                Section("Disciplinary Actions") {
                    List {
                        NavigationLink {
                            DisciplinaryActionListSheet(
                                dataController: dataController,
                                credential: credential
                            )
                        } label: {
                            HStack {
                                Text("Disciplinary Actions:")
                            }//: HSTACK
                            .badge(allDAIs.count)
                            .accessibilityElement()
                            .accessibilityLabel("Disciplinary actions taken against this credential")
                            .accessibilityHint("^[\(allDAIs.count) action taken] (inflect: true)")
                        }//: NAV LINK
                       
                    }//: LIST
                }//: SECTION
                
                
                // MARK: RESTRICTIONS
                CredentialRestrictionsSectionView(credential: credential)
                   
                
                // MARK: SAVE Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            saveChanges()
                        } label: {
                            Label("Save", systemImage: "internaldrive.fill")
                                .font(.title)
                        }
                        Spacer()
                    }//: HSTACK
                }//: SECTION
                
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
                
            // MARK: - ON RECEIVE
            .onReceive(credential.objectWillChange) { _ in
                dataController.queueSave()
            }//: ON RECEIVE
            
            .onSubmit {dataController.save()}
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

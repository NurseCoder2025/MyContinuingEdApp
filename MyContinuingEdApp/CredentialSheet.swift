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

struct CredentialSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Existing credential object being passed in for editing
    let credential: Credential?
    
    // MARK: Credential properties
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var number: String = ""
    @State private var expiration: Date?
    @State private var renewalLength: Double = 24.0   // 2 year renewal period is common across many professions
    @State private var activeYN: Bool = true
    @State private var whyInactive: String = ""
    @State private var restrictedYN: Bool = false
    @State private var restrictionsDetails: String = ""
    
    // MARK: Issuer related properties
    @State private var issueDate: Date?
    @State private var credIssuer: Issuer?

    // Show an alert if a credential type has not been selected by the user
    @State private var showNoCredTypeAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var allDAIs: [DisciplinaryActionItem] {
        var actions: [DisciplinaryActionItem] = []
        // ONLY fetch disciplinary actions if an existing credential is being edited
        if let cred = credential {
            let request = DisciplinaryActionItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionName, ascending: true)]
            request.predicate = NSPredicate(format: "credential == %@", cred)
            actions = (try? dataController.container.viewContext.fetch(request)) ?? []
        }
        
        return actions
    }
    
  
    // MARK: - BODY
    var body: some View {
    
        // MARK: - Main Nav VIEW
        NavigationView {
            Form {
                // MARK: BASIC INFO
                BasicCredentialInfoView(
                    name: $name,
                    type: $type,
                    number: $number,
                    credIssuer: $credIssuer
                )
                
                
                // MARK: ACTIVE Y or N?
                ActiveCredentialSectionView(activeYN: $activeYN, whyInactive: $whyInactive)
                
                // MARK: Issue & Renewal Section
                CredentialIssueAndRenewalSectionView(
                    credential: credential,
                    renewalLength: $renewalLength
                )
                
                // MARK: Next Expiration
                // Will be shown to the user ONLY if editing an existing credential
                CredentialNextExpirationSectionView(
                    credential: credential,
                    renewalLength: renewalLength
                )
                
                // TODO: Pass credential to DisciplinaryActionListSheet
                Section("Disciplinary Actions") {
                    List {
                        NavigationLink {
                            DisciplinaryActionListSheet()
                        } label: {
                            HStack {
                                Text("Disciplinary Actions:")
                            }//: HSTACK
                        }//: NAV LINK
                        .badge(allDAIs.count)
                    }//: LIST
                }//: SECTION
                
                
                // MARK: RESTRICTIONS
                CredentialRestrictionsSectionView(
                    restrictedYN: $restrictedYN,
                    restrictionsDetails: $restrictionsDetails
                )
                
                
                // MARK: SAVE Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            mapAndSave()
                        } label: {
                            Label("Save", systemImage: "internaldrive.fill")
                                .font(.title)
                        }
                        Spacer()
                    }//: HSTACK
                }//: SECTION
                
            }//: FORM
        // MARK: - NAV TITLE
            .navigationTitle(credential == nil ? "Add Credential" : "Credential Info")
           
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {dismiss()}){
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mapAndSave()
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
                
            
            //: MARK: - ON APPEAR
            // If an existing credential is being edited, map its properties to the state variables
            .onAppear {
                if let existingCred = credential {
                    mapToEntity(for: existingCred)
                }
                    
            }// ON APPEAR
            
        }//: NAV VIEW
    }//: BODY
    
    // MARK: - METHODS
    
    /// Function maps Credential entity properties to fields in the UI for saving changes.
    /// - Parameter cred: Credential object that is being edited
    func mapToFields(for cred: Credential) {
        cred.name = name
        cred.credentialType = type
        cred.credentialNumber = number
        cred.issueDate = issueDate
        cred.renewalPeriodLength = renewalLength
        cred.isActive = activeYN
        cred.isRestricted = restrictedYN
        cred.restrictions = restrictionsDetails
        cred.inactiveReason = whyInactive
        
        // If an issuer has been selected
        if let selectedIssuer = credIssuer {
            cred.issuer = selectedIssuer
        }
    }//: MAP TO FIELDS
    
    /// This function maps UI controls to an existing Credential entity's properties for editing.  Use when loading
    /// a sheet or view which is receiving an existing Credential object as an argument.  This way existing values will
    /// appear in the UI controls.
    /// - Parameter existingCred: Credential object being passed in for editing
    func mapToEntity(for existingCred: Credential) {
        name = existingCred.credentialName
        type = existingCred.credentialCreType
        number = existingCred.credentialCreNumber
        issueDate = existingCred.issueDate
        renewalLength = existingCred.renewalPeriodLength
        activeYN = existingCred.isActive
        restrictedYN = existingCred.isRestricted
        restrictionsDetails = existingCred.credentialRestrictions
        whyInactive = existingCred.credentialInactiveReason
        
        if let issuer = existingCred.issuer {
            credIssuer = issuer
        }
    }//: MAP To ENTITY
    
    /// This function first maps the UI control fields to either an existing Credential object or new Credential object,
    /// then saves the changes to Core Data.
    func mapAndSave() {
        // Checking to make sure a credential type has been selected
        if type == ""  {
            showNoCredTypeAlert = true
            return
        } else {
            // If editing an existing credential, map changes to that object
            if let existingCred = credential {
                mapToFields(for: existingCred)
            } else {
                // Creating a new credential object
                let newCred = dataController.createNewCredential()
                mapToFields(for: newCred)
            }
            
            dataController.save()
            dismiss()
        }
    }//: MAP & SAVE
    
}

 // MARK: - PREVIEW
#Preview {
    CredentialSheet(credential: .example)
        .environmentObject(DataController(inMemory: true))
}

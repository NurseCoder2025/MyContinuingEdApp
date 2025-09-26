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
    
    // License related properties
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

    // Hold the newly created Credential for sheet presentation
    @State private var newCredential: Credential?
    
  
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
                    renewalLength: renewalLength,
                    newCredential: $newCredential
                )
               
                
                // MARK: RESTRICTIONS
                CredentialRestrictionsSectionView(
                    restrictedYN: $restrictedYN,
                    restrictionsDetails: $restrictionsDetails
                )
                
                // TODO: Add Disciplinary Action Hx section
                
                // MARK: SAVE Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            mapAndSave()
                            dismiss()
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
                Button(action: {dismiss()}){
                    DismissButtonLabel()
                }.applyDismissStyle()
            }//: TOOLBAR
            
        }//: NAV VIEW
    }//: BODY
    
    // MARK: - METHODS
    
    func mapCredProperties(for cred: Credential) {
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
    }
    
    func mapAndSave() {
        // IF an existing Credential is being edited
        if let existingCred = credential {
            mapCredProperties(for: existingCred)
            
            dataController.save()
            // IF a new Credential object was created prior to tapping on the save button
        } else if let createdCred = newCredential {
            mapCredProperties(for: createdCred)
            dataController.save()
        } else {
            // Don't make a new Credential object unless none was passed in and a new object
            // wasn't created earlier (see CredentialSpecialCECatSelectionView)
            let context = dataController.container.viewContext
            let newCredential = Credential(context: context)
            
            mapCredProperties(for: newCredential)
            
            dataController.save()
            
        }
        
        // Print out number of credential objects and their name
        print("------------------Diagnostic: Credential Objects --------------")
        let context = dataController.container.viewContext
        let request = Credential.fetchRequest()
        let allCreds = (try? context.fetch(request)) ?? []
        
        let count = (try? context.count(for: request)) ?? 0
        print("Total Credential objects: \(count)")
        print("")
        
        for cred in allCreds {
            print(cred.credentialName)
        }
        
    }//: MAP & SAVE
    
}

 // MARK: - PREVIEW
#Preview {
    CredentialSheet(credential: .example)
}

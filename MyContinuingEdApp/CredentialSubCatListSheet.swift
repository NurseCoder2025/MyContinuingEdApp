//
//  CredentialSubCatListSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/6/25.
//

// Purpose: To display all credentials which are of the same type (i.e. License,
// Certification, etc.)

import CoreData
import SwiftUI

struct CredentialSubCatListSheet: View {
    //: MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Property for storing a selected Credential from the list
    @State private var selectedCredential: Credential?
    
    // Property for storing a Credential to edit
    @State private var credentialToEdit: Credential?
    
    // Alert properties for deleting a credential object
    @State private var showDeleteAlert: Bool = false
    
    // Property for adding a new Credential object
    @State private var showCredentialSheet: Bool = false

    // The singular, lowercased, string value from the CredentialType enum is passed in here
    let credentialType: String
    
    //: MARK: - COMPUTED PROPERTIES
    
    /// Computed property that returns an array of all Credential objects that match
    /// the passed-in credentialType string.  Sorted by name.
    var credentialsOfType: [Credential] {
        let fetchRequest: NSFetchRequest<Credential> = Credential.fetchRequest()
        
        // IF a specific type of credential is being requested, filter by that type
        if credentialType != "all" {
            fetchRequest.predicate = NSPredicate(format: "credentialType == %@", credentialType)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let context = dataController.container.viewContext
        let creds = (try? context.fetch(fetchRequest)) ?? []
        
        return creds
    }
    
    
    /// Computed property which returns a dictionary of credentials grouped by the first letter of their name
    var alphabeticalCredentialGroupings: [String: [Credential]] {
        Dictionary(grouping: credentialsOfType) { cred in
            String(cred.credentialName.prefix(1).uppercased())
        }
    }
    
    /// Creates an array of all first letters of the credential names for section headers
    var sortedSectionKeys: [String] {
        alphabeticalCredentialGroupings.keys.sorted()
    }
    
    
    //: MARK: - BODY
    var body: some View {
            if credentialsOfType.isEmpty {
                NoCredSubTypeView(credentialType: credentialType)
            } else {
                VStack {
                    // MARK: - TOP BAR
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Dismiss")
                        }//: BUTTON
                        .padding([.top, .leading], 20)
                        
                        Spacer()
                        
                        Button {
                            showCredentialSheet = true
                        } label: {
                            Label("Add Credential", systemImage: "plus")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                        }//: BUTTON
                        .padding([.top, .trailing], 20)
                        
                    }//: HSTACK
                    
                    Spacer()
                    // MARK: - Heading
                    HStack {
                        Text(credentialType == "all" ? "All Credentials" : "\(credentialType.capitalized)s")
                            .font(.title)
                            .bold()
                            .padding(.leading, 20)
                        Spacer()
                    }//: HSTACK
                    
                    // MARK: - LIST
                    List {
                        ForEach(sortedSectionKeys, id: \.self) { key in
                            Section(header: Text(key)) {
                                
                                // Rows for each credential in that letter section
                                ForEach(alphabeticalCredentialGroupings[key] ?? []) { cred in
                                    Button {
                                        credentialToEdit = cred
                                    } label: {
                                        HStack {
                                            Text(cred.credentialName)
                                            Text("(\(cred.capitalizedCreType))")
                                                .foregroundStyle(.secondary)
                                        }//: HSTACK
                                    }
                                    //: MARK: - SWIPE ACTIONS
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            selectedCredential = cred
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }//: SWIPE ACTIONS
                                    
                                }//: LOOP
                                
                            }//: SECTION
                            
                        }//: LOOP (sortedSectionKeys)
                        
                    }//: LIST
                }//: VSTACK
                //: MARK: - ALERTS
                .alert("Delete Credential?", isPresented: $showDeleteAlert, presenting: selectedCredential) { cred in
                    Button("Delete", role: .destructive) {
                        deleteCredential(cred)
                    }
                    Button("Cancel", role: .cancel) {
                        selectedCredential = nil
                    }
                } message: { cred in
                    Text("Are you sure you want to delete \(cred.credentialName)? This will delete any associated disciplinary actions and renewal periods. However, any CE activities entered under this credential will remain.")
                }
                //: MARK: - SHEETS
                .sheet(isPresented: $showCredentialSheet) {
                    CredentialSheet(credential: nil)
                }// : SHEET
                
                .sheet(item: $credentialToEdit) { cred in
                    CredentialSheet(credential: cred)
                }//: SHEET
                
            }//: IF-ELSE
        
    }//: BODY
    
    //: MARK: - FUNCTIONS
    func deleteCredential(_ credential: Credential) {
        let context = dataController.container.viewContext
        context.delete(credential)
        try? context.save()
        selectedCredential = nil
    }
    
    
}//: STRUCT


//: MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    let context = controller.container.viewContext

    // Adding sample data for preview
    let sampleCred1 = controller.createNewCredential()
    sampleCred1.credentialName = "Sample License A"
    sampleCred1.credentialType = "license"
    try? context.save()

    return CredentialSubCatListSheet(credentialType: "license")
        .environmentObject(controller)
}

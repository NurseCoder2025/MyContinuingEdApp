//
//  IssuerListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/4/25.
//

import CoreData
import SwiftUI

// This file creates a sheet containing a list of all entered credential issuers.  The user
// can use this list to select a different issuer for a given credential or add, edit, or delete
// existing issuers.


struct IssuerListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Passing in a credential object to allow the user to select from this view which issuer is
    // assigned to the given credential
    @ObservedObject var credential: Credential
    
    // Property for storing a newly created Issuer
    @State private var newIssuer: Issuer?
    
    // Property related to the selection of an issuer object
    @State private var selectedIssuer: Issuer?
    
    // Property for adding a new issuer
    @State private var showIssuerSheet: Bool = false
    
    // Properties for deleting an issuer
    @State private var showDeletionWarning: Bool = false
    
    // MARK: - CORE DATA FETCH REQUESTS
    @FetchRequest(sortDescriptors: [SortDescriptor(\.issuerName)]) var allIssuers: FetchedResults<Issuer>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allIssuers.isEmpty {
               NoIssuersView()
            } else {
                List {
                    ForEach(allIssuers) { issuer in
                        Button {
                            selectedIssuer = issuer
                            credential.issuer = issuer
                        } label: {
                            IssuerRowView(
                                issuer: issuer,
                                isSelected: selectedIssuer == issuer
                            )
                        }//: BUTTON
                            .swipeActions {
                                
                                // MARK: Edit Issuer
                                Button {
                                    selectedIssuer = issuer
                                    showIssuerSheet = true
                                } label: {
                                    Label("Edit Issuer", systemImage: "pencil")
                                        .labelStyle(.iconOnly)
                                }
                                
                                // MARK: Delete Issuer
                                Button(role: .destructive) {
                                    selectedIssuer = issuer
                                    showDeletionWarning = true
                                } label: {
                                    Label("Delete Issuer", systemImage: "trash.fill")
                                        .labelStyle(.iconOnly)
                                }
                            }//: SWIPE ACTIONS
                        
                    }//: LOOP
                }//: LIST
                .navigationTitle("Credential Issuers")
                // MARK: - TOOLBAR
                .toolbar {
                    // MARK: Adding a new Issuer
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            selectedIssuer = nil
                            newIssuer = dataController.createNewIssuer()
                            showIssuerSheet = true
                        } label: {
                            Label("Add Issuer", systemImage: "plus")
                        }
                    }//: TOOLBAR ITEM
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {dismiss()}) {
                            Text("Dismiss")
                        }
                    }//: TOOLBAR ITEM
                    
                }//: TOOLBAR
                
                // MARK: - SHEETS
                .sheet(isPresented: $showIssuerSheet) {
                    if let createdIssuer = newIssuer {
                        IssuerSheet(issuer: createdIssuer)
                        // Delete object if user cancels/dismisses sheet before saving it
                            .onDisappear {
                                if createdIssuer.issuerName == "New Issuer" {
                                    dataController.delete(createdIssuer)
                                }
                            }//: ON DISAPPEAR
                    } else {
                        if let issuerToEdit = selectedIssuer {
                            IssuerSheet(issuer: issuerToEdit)
                        }//: IF LET
                    }//: IF LET
                    
                }//: SHEET
                
                // MARK: - ALERTS
                .alert("Delete Issuer?", isPresented: $showDeletionWarning) {
                    Button("DELETE", role: .destructive) {
                        deleteIssuer()
                        selectedIssuer = nil
                        showDeletionWarning = false
                    }
                    Button("Cancel", role: .cancel) {
                        selectedIssuer = nil
                        showDeletionWarning = false
                    }
                } message: {
                    Text("Deleting the selected issuer will delete all associated data with it, including any disciplinary actions recorded.  Are you sure you wish to delete it?")
                }//: DELETION WARNING
                
            }//: IF - ELSE
        }//: NAV VIEW
    }
    // MARK: - View METHODS
    /// Deletes the swipped issuer object from the viewContext and, if saved, persistent
    /// storage.
    func deleteIssuer() {
        if let unwantedIssuer = selectedIssuer {
            dataController.delete(unwantedIssuer)
        }
        dataController.save()
    } //: DELETE Function
}

// MARK: - PREVIEW
#Preview {
    IssuerListSheet(credential: .example)
}

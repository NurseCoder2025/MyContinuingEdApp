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
    
    // Property for adding a new issuer
    @State private var showIssuerSheet: Bool = false
    
    // Properties for editing an existing issuer
    @State private var selectedIssuer: Issuer?
    @State private var issuerToEdit: Issuer?
    
    // Properties for deleting an issuer
    @State private var issuerToDelete: Issuer?
    @State private var showDeletionWarning: Bool = false
    
    // MARK: - CORE DATA FETCH REQUESTS
    @FetchRequest(sortDescriptors: [SortDescriptor(\.issuerName)]) var allIssuers: FetchedResults<Issuer>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allIssuers.isEmpty {
               NoIssuersView()
            } else {
                List(selection: $selectedIssuer) {
                    ForEach(allIssuers) { issuer in
                        IssuerRowView(issuer: issuer, selectedIssuer: selectedIssuer)
                            .swipeActions {
                                // MARK: Edit Issuer
                                Button {
                                    issuerToEdit = issuer
                                } label: {
                                    Label("Edit Issuer", systemImage: "pencil")
                                        .labelStyle(.iconOnly)
                                }
                                // MARK: Delete Issuer
                                Button(role: .destructive) {
                                    issuerToDelete = issuer
                                    showDeletionWarning = true
                                } label: {
                                    Label("Delete Issuer", systemImage: "trash.fill")
                                        .labelStyle(.iconOnly)
                                }
                            }
                    }//: LOOP
                }//: LIST
                .navigationTitle("Credential Issuers")
                // MARK: - TOOLBAR
                .toolbar {
                    // MARK: Adding a new Issuer
                    Button {
                        showIssuerSheet = true
                    } label: {
                        Label("Add Issuer", systemImage: "plus")
                    }
                    Button(action: {dismiss()}) {
                        DismissButtonLabel()
                    }.applyDismissStyle()
                }//: TOOLBAR
                // MARK: - SHEETS
                .sheet(isPresented: $showIssuerSheet) {
                    IssuerSheet(issuer: nil)
                }
                .sheet(item: $issuerToEdit) { issuer in
                    IssuerSheet(issuer: issuer)
                }
                .alert("Delete Issuer?", isPresented: $showDeletionWarning) {
                    Button("DELETE", role: .destructive) {
                        deleteIssuer()
                        issuerToDelete = nil
                        showDeletionWarning = false
                    }
                    Button("Cancel", role: .cancel) {
                        issuerToDelete = nil
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
        if let unwantedIssuer = issuerToDelete {
            dataController.delete(unwantedIssuer)
        }
        dataController.save()
    } //: DELETE Function
}

// MARK: - PREVIEW
#Preview {
    IssuerListSheet()
}

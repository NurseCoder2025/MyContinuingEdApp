//
//  IssuerListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/4/25.
//

import SwiftUI

// This file creates a sheet containing a list of all entered credential issuers.  The user
// can use this list to select a different issuer for a given credential or add, edit, or delete
// existing issuers.


struct IssuerListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: ViewModel
    
    // Passing in a credential object to allow the user to select from
    // this view which issuer is assigned to the given credential
    @ObservedObject var credential: Credential
    
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if viewModel.allIssuers.isEmpty {
               NoIssuersView()
            } else {
                List {
                    ForEach(viewModel.allIssuers) { issuer in
                        Button {
                            // Add action
                            viewModel.tapSelectsAndAssignsIssuer(someIssuer: issuer, someCred: credential)
                        } label: {
                            IssuerRowView(
                                issuer: issuer,
                                isSelected: viewModel.selectedIssuer == issuer
                            )
                        }//: BUTTON
                            .swipeActions {
                                
                                // MARK: Edit Issuer
                                Button {
                                    viewModel.editSelectedIssuer(issuer)
                                } label: {
                                    Label("Edit Issuer", systemImage: "pencil")
                                        .labelStyle(.iconOnly)
                                }
                                
                                // MARK: Delete Issuer
                                Button(role: .destructive) {
                                    viewModel.deleteIssuer(issuer)
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
                            viewModel.addNewIssuer()
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
                .sheet(isPresented: $viewModel.showIssuerSheet) {
                    if let createdIssuer = viewModel.newIssuer {
                        IssuerSheet(dataController: viewModel.dataController, issuer: createdIssuer)
                        // Delete object if user cancels/dismisses sheet before saving it
                            .onDisappear {
                                if createdIssuer.issuerName == "New Issuer" {
                                    viewModel.dataController.delete(createdIssuer)
                                }
                            }//: ON DISAPPEAR
                    } else {
                        if let issuerToEdit = viewModel.selectedIssuer {
                            IssuerSheet(dataController: viewModel.dataController, issuer: issuerToEdit)
                        }//: IF LET
                    }//: IF LET
                    
                }//: SHEET
                
                // MARK: - ALERTS
                .alert("Delete Issuer?", isPresented: $viewModel.showDeletionWarning) {
                    Button("DELETE", role: .destructive) {
                        viewModel.confirmedDeleteIssuer()
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.cancelIssuerDelete()
                    }
                } message: {
                    Text("Deleting the selected issuer will delete all associated data with it, including any disciplinary actions recorded.  Are you sure you wish to delete it?")
                }//: DELETION WARNING
                
            }//: IF - ELSE
        }//: NAV VIEW
    }
    
    
    // MARK: - INIT
    init(dataController: DataController, credential: Credential) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.credential = credential
        
    }//: INIT
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    IssuerListSheet(dataController: .preview, credential: .example)
}

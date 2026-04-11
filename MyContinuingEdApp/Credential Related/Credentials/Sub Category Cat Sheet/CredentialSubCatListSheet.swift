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
import UIKit

struct CredentialSubCatListSheet: View {
    //: MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: ViewModel
    
    //: MARK: - BODY
    var body: some View {
        if viewModel.credentialsOfType.isEmpty {
            NoCredSubTypeView(credentialType: viewModel.credentialType)
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
                            viewModel.showCredentialSheet = true
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
                        Text(viewModel.credentialType == "all" ? "All Credentials" : "\(viewModel.credentialType.capitalized)s")
                            .font(.title)
                            .bold()
                            .padding(.leading, 20)
                        Spacer()
                    }//: HSTACK
                    
                    // MARK: - LIST
                    List {
                        ForEach(viewModel.sortedSectionKeys, id: \.self) { key in
                            Section(header: Text(key)) {
                                
                                // Rows for each credential in that letter section
                                ForEach(viewModel.alphabeticalCredentialGroupings[key] ?? []) { cred in
                                    Button {
                                        viewModel.credentialToEdit = cred
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
                                            viewModel.selectedCredential = cred
                                            viewModel.showDeleteAlert = true
                                            if viewModel.showDeleteAlert {
                                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                            }
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
                .alert("Delete Credential?", isPresented: $viewModel.showDeleteAlert, presenting: viewModel.selectedCredential) { cred in
                    Button("Delete", role: .destructive) {
                        viewModel.deleteCredential(cred)
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.selectedCredential = nil
                    }
                } message: { cred in
                    Text("""
                    Are you sure you want to delete \(cred.credentialName)? 
                    This will delete any associated disciplinary actions and 
                    renewal periods. However, any CE activities entered under 
                    this credential will remain.
                    """)
                }
                //: MARK: - SHEETS
                .sheet(isPresented: $viewModel.showCredentialSheet) {
                    let newCred = viewModel.dataController.createNewCredential()
                    CredentialSheet(credential: newCred)
                }// : SHEET
                
                .sheet(item: $viewModel.credentialToEdit) { cred in
                    CredentialSheet(credential: cred)
                }//: SHEET
                
            }//: IF-ELSE
        
    }//: BODY

   // MARK: - INIT
    init(dataController: DataController, type: String) {
        let viewModel = ViewModel(dataController: dataController, credType: type)
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
    
    
}//: STRUCT


//: MARK: - PREVIEW
#Preview {
    CredentialSubCatListSheet(dataController: .preview, type: "license")
}

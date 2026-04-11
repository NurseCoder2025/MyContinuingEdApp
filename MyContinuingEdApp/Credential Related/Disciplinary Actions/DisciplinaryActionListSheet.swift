//
//  DisciplinaryActionListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/16/25.
//


// Purpose: show all Disciplinary Action Items in a list for the user to edit and add as needed

// 10-14-25 update: Adding the credential property in order for disciplinary actions to be associated with a
// specific credential

import CoreData
import SwiftUI

struct DisciplinaryActionListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: ViewModel
    
    // Passing in a credential object for which all associated disciplinary actions will be assigned to
    @ObservedObject var credential: Credential
    
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if viewModel.allDAIs.isEmpty {
                NoDAIsView(credential: credential, onAddDAI: {
                    viewModel.newDAI = viewModel.dataController.createNewDAI(for: credential)
                    viewModel.addNewDAI = true
                })
            } else {
                List {
                    ForEach(viewModel.allDAIs) {dai in
                        Group {
                            VStack {
                                HStack {
                                    Text(dai.daiActionName)
                                        .lineLimit(1)
                                    Text(tradDateFormatter.string(from: dai.daiActionStartDate))
                                }//: HSTACK
                                Text(dai.daiActionType)
                                    .italic()
                            }//: VSTACK
                        }//: GROUP
                        .swipeActions {
                            // Edit
                            Button {
                                viewModel.editExistingDAI(someDAI: dai)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            // Delete
                            Button(role: .destructive) {
                                viewModel.deleteDAI(someDAI: dai)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }//: LOOP
                }//: LIST
                .navigationTitle("Disciplinary Actions")
                // MARK: - TOOLBAR
                .toolbar {
                    // Add new DAI
                    Button {
                        viewModel.addNewDAIObject()
                    } label: {
                        Label("Add Disciplinary Action", systemImage: "plus")
                    }
                    
                }//: TOOLBAR
                // MARK: - SHEETS
                // For adding a new DAI item
                .sheet(isPresented: $viewModel.addNewDAI) {
                    if let createdDAI = viewModel.newDAI {
                        DisciplinaryActionItemSheet(disciplinaryAction: createdDAI)
                    }
                }//: SHEET
                // For editing a DAI item
                .sheet(item: $viewModel.daiTOEdit) {_ in
                    if let selectedDAI = viewModel.daiTOEdit {
                        DisciplinaryActionItemSheet(disciplinaryAction: selectedDAI)
                    }//: IF LET
                }//: SHEET
                // MARK: - ALERTS
                .alert("Delete Disciplinary Action", isPresented: $viewModel.showDeletionWarning) {
                    Button("Delete", role: .destructive, action: {viewModel.confirmedDeleteDAI()})
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete this disciplinary action?  Once deleted it cannot be undone.")
                }
            }//: IF-ELSE
        }//: NAV VIEW
    }
    
    // MARK: - INIT
    init(dataController: DataController, credential: Credential) {
        self.credential = credential
        
        let viewModel = ViewModel(dataController: dataController, credential: credential)
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
}

// MARK: - PREVIEW
#Preview {
    DisciplinaryActionListSheet(dataController: .preview, credential: .example)
}

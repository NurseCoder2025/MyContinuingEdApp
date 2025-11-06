//
//  SpecialCECatsManagementSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/17/25.
//

// Purpose: To allow the user to select which special CE categories should be associated with a given
// credential (i.e. a lawyer credential requiring so many hours of ethics)

import CoreData
import SwiftUI

/// This struct is intended for use in both ActivityView as well as in CredentialSheet so that the user can create/assign special
/// CE categories to both Credential and CeActivity objects.  While the struct is initialized with optional activity and credential
/// properties set to nil by default, one of those two properties should be assigned an object in order for things to work properly.
///
/// - Parameters:
///     - credential: [Optional] Credential object if the user is to be assigning a special ce catetory to a particular Credential
///     - activity: [Optional] CeActivity object if the user is to designate a specific CE activity as counting towards the special CE category
struct SpecialCECatsManagementSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    private var dataController: DataController
    
    @StateObject private var viewModel: ViewModel
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allSpecialCats: FetchedResults<SpecialCategory>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allSpecialCats.isEmpty {
                NoSpecialCatsView(dataController: dataController) {
                    viewModel.addNewSpecialCategory()
                }
            } else {
                VStack {
                    Text(viewModel.sheetForString)
                        .font(.title)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 15)
                    List() {
                        // MARK: ASSIGNED SPECIAL CATS - HEADER
                        ForEach(allCredentials) { credential in
                            Section(header: Text(credential.credentialName)) {
                                // MARK: ROWS
                                ForEach(viewModel.specialCatsAssignedTo(credential: credential)) { specialCat in
                                    SpecialCatRowView(
                                        specialCat: specialCat,
                                        credential: viewModel.credential,
                                        activity: viewModel.activity,
                                        onTap: {
                                            viewModel.tapToAddOrRemove(category: specialCat)
                                        },
                                        onEdit: {
                                            viewModel.specialCatToEdit = specialCat
                                        },
                                        onDelete: {
                                            viewModel.specialCatToDelete = specialCat
                                            viewModel.showDeleteWarning = true
                                        }
                                    )
                                }//: LOOP
                                
                            }//: SECTION
                        }//: LOOP
                        
                        // MARK: UNASSIGNED
                        Section(
                            header: Text("Unassigned to Any Credential"),
                            footer: Text("To assign any of these categories to a Credential, swipe left and tap on the edit button. Then, at the bottom of the screen tap on the assignment picker to select the desired Credential.")
                        ){
                            ForEach(viewModel.specialCatsAssignedTo(credential: nil)) { specialCat in
                                SpecialCatRowView(
                                    specialCat: specialCat,
                                    credential: viewModel.credential,
                                    activity: viewModel.activity,
                                    onTap: {
                                        viewModel.tapToAddOrRemove(category: specialCat)
                                    },
                                    onEdit: {
                                        viewModel.specialCatToEdit = specialCat
                                    },
                                    onDelete: {
                                        viewModel.specialCatToDelete = specialCat
                                        viewModel.showDeleteWarning = true
                                    }
                                )
                            }//: LOOP
                        }//:SECTION
                        
                    }//: LIST
                    
                }//: VSTACK
                .navigationTitle("Assign CE Category")
                // MARK: - TOOLBAR
                .toolbar {
                    // Adding a new Special Category
                    ToolbarItem {
                        Button {
                            viewModel.addNewSpecialCategory()
                        } label: {
                            Label("Add Special Category", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                        
                    }//: TOOLBAR ITEM
                    
                    
                    // Dismissing the sheet without saving changes
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "clear.fill")
                        }
                    } //: CANCEL TOOLBAR ITEM
                    
                }//: TOOLBAR
                // MARK: - SHEETS
                // Adding Special Category
                .sheet(item: $viewModel.addedSpecialCategory){ _ in
                    if let newSpecialCat = viewModel.addedSpecialCategory {
                        SpecialCategorySheet(existingCat: newSpecialCat)
                    }
                }//: SHEET
                
                .sheet(item: $viewModel.specialCatToEdit) { _ in
                    if let specialCatForEditing = viewModel.specialCatToEdit {
                        SpecialCategorySheet(existingCat: specialCatForEditing)
                    }
                }//: SHEET
                
                
                // MARK: - ALERTS
                .alert("Delete Special CE Category", isPresented: $viewModel.showDeleteWarning) {
                    Button("Delete", role: .destructive, action: {viewModel.deleteSelectedCategory()})
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You are about to delete the \(viewModel.specialCatToDelete?.specialName ?? "selected") category. Are you sure?")
                }
            }//: IF - ELSE
            
        }//: NAV VIEW
    } //: BODY
    
    
   // MARK: - INIT
    init(dataController: DataController, credential: Credential? = nil, activity: CeActivity? = nil) {
       self.dataController = dataController
       let viewModel = ViewModel(dataController: dataController, cred: credential, activity: activity)
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }//: INIT()
    
}//: STRUCT

//
//  SpecialCategoryListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import CoreData
import SwiftUI

// Purpose: To show a list of all entered Special Category objects and allow the user to add, edit, and delete them at will

// UPDATE: NO longer need this specific sheet as all functionality has been added
// to the SpecialCECAtsManagementSheet file for simplicity

struct SpecialCategoryListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Properties for showing the SpecialCategorySheet (for adding a new object or editing a new one)
    @State private var editSpecialCategory: Bool = false
    @State private var addNewSpecialCategory: Bool = false
    
    // Properties to store selected object for editing/deleting
    @State private var specialCatToEdit: SpecialCategory?
    @State private var specialCatToDelete: SpecialCategory?
    
    // Deletion alert properties
    @State private var showDeleteWarning: Bool = false
    
    // MARK: - CORE DATA FETCH REQUESTS
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allSpecialCategories: FetchedResults<SpecialCategory>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            List {
                ForEach(allSpecialCategories) { category in
                    VStack {
                        Text(category.specialName)
                            .font(.title3)
                            .bold()
                        Text("Required hours: \(category.requiredHours)")
                    }//: VSTACK
                    .swipeActions {
                        // EDIT button
                        Button {
                            specialCatToEdit = category
                            editSpecialCategory = true  // may not need this line of code
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        // DELETE button
                        Button(role: .destructive) {
                            specialCatToDelete = category
                            showDeleteWarning = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                    }//: SWIPE ACTIONS
                }//: LOOP
                
            }//: LIST
            .navigationTitle("Special CE Categories")
            // MARK: - TOOLBAR
            .toolbar {
                // Add new category button
                Button {
                    addNewSpecialCategory = true
                } label: {
                    Label("Add Special CE Category", systemImage: "plus")
                }
                
                // Close sheet button
                Button {
                    dismiss()
                } label: {
                    DismissButtonLabel()
                }.applyDismissStyle()
                
            }//: TOOLBAR
            // MARK: - SHEETS
            .sheet(item: $specialCatToEdit) { category in
                SpecialCategorySheet(existingCat: category)
            }
            .sheet(isPresented: $addNewSpecialCategory) {
                SpecialCategorySheet(existingCat: nil)
            }
            
            // MARK: - ALERTS
            .alert("Delete Special CE Category", isPresented: $showDeleteWarning) {
                Button("Delete", role: .destructive, action: {deleteSelectedCategory()})
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You are about to delete the \(specialCatToDelete?.specialName ?? "selected") category. Are you sure?")
            }
            
        }//: NAV VIEW
        
        
    }
    // MARK: - FUNCTIONS
    func deleteSelectedCategory() {
        if let category = specialCatToDelete {
            dataController.delete(category)
        }
        
        dataController.save()
    }
}

// MARK: - PREVIEW
#Preview {
    SpecialCategoryListSheet()
}

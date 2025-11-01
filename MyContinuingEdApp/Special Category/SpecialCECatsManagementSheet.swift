//
//  Credential-SpecialCatsSelectionSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/17/25.
//

// Purpose: To allow the user to select which special CE categories should be associated with a given
// credential (i.e. a lawyer credential requiring so many hours of ethics)

import CoreData
import SwiftUI

struct SpecialCECatsManagementSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Passing in the CeActivity object for which special categories will be assigned
    @ObservedObject var activity: CeActivity
    
    // Property for adding a new SpecialCategory object if the user needs to
    @State private var addNewSpecialCat: Bool = false
    
    // Property for showing the SpecialCategorySheet for editing a category
    @State private var editSpecialCategory: Bool = false
    
    // Properties for holding a special category for editing or deleting purposes
    @State private var specialCatToEdit: SpecialCategory?
    @State private var specialCatToDelete: SpecialCategory?
    
    // Deletion alert property
    @State private var showDeleteWarning: Bool = false
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allSpecialCats: FetchedResults<SpecialCategory>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allSpecialCats.isEmpty {
                NoSpecialCatsView()
            } else {
                VStack {
                    Text("For: \(activity.ceTitle)")
                        .font(.title)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 15)
                    List(allSpecialCats) { cat in
                        HStack {
                            Text(cat.specialName)
                            Spacer()
                            if activity.specialCat == cat {
                                Image(systemName: "checkmark")
                            }
                        }//: HSTACK (ROW)
                        // MARK: - SWIPE ACTIONS
                        .swipeActions {
                            // EDIT button
                            Button {
                                specialCatToEdit = cat
                                editSpecialCategory = true  // may not need this line of code
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            
                            // DELETE button
                            Button(role: .destructive) {
                                specialCatToDelete = cat
                                showDeleteWarning = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                        }//: SWIPE
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if activity.specialCat == cat {
                                activity.specialCat = nil
                            } else {
                                activity.specialCat = cat
                            }
                        }
                        
                    }//: LIST
                    // MARK: - Dismiss BUTTON
                    // Save assignments to credential object
                    Button {
                        dismiss()
                    } label: {
                        Label("Dismiss", systemImage: "internaldrive.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                }//: VSTACK
                .navigationTitle("Assign CE Category")
                // MARK: - TOOLBAR
                .toolbar {
                    // Adding a new Special Category
                    ToolbarItem {
                        Button {
                            addNewSpecialCat = true
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
                .sheet(isPresented: $addNewSpecialCat){
                    let newSpecialCat = dataController.createNewSpecialCategory()
                    SpecialCategorySheet(existingCat: newSpecialCat)
                }
                
                // TODO: Fix bug where passed in cat data doesn't show up in sheet
                .sheet(item: $specialCatToEdit) { category in
                    SpecialCategorySheet(existingCat: category)
                }
                
                // MARK: - ON APPEAR
                
                
                // MARK: - ALERTS
                .alert("Delete Special CE Category", isPresented: $showDeleteWarning) {
                    Button("Delete", role: .destructive, action: {deleteSelectedCategory()})
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You are about to delete the \(specialCatToDelete?.specialName ?? "selected") category. Are you sure?")
                }
            }//: IF - ELSE
            
        }//: NAV VIEW
    } //: BODY
    
    // MARK: - FUNCTIONS
    
    /// Deletes the selected special CE category object once confirmed by the user
    func deleteSelectedCategory() {
        if let category = specialCatToDelete {
            dataController.delete(category)
        }
        
        dataController.save()
    }
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    let context = controller.container.viewContext

    let specialCat = SpecialCategory(context: context)
    specialCat.name = "Category A"
    specialCat.abbreviation = "Cat A"

    let someActivity = CeActivity(context: context)
    someActivity.activityTitle = "A Great CE!"
    someActivity.ceAwarded = 1.0
    someActivity.specialCat = specialCat

    try? context.save()

    return SpecialCECatsManagementSheet(activity: someActivity)
        .environmentObject(controller)
        .environment(\.managedObjectContext, context) // Ensure fetch request sees preview data
}

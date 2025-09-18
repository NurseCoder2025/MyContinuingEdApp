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

struct SpecialCECatAssignmentManagementSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Passing in the Credential object for which special categories will be assigned
    @ObservedObject var credential: Credential
    
    // Special category objects that the user wants to assign to the credential
    @State private var selectedCats: Set<SpecialCategory> = []
    
    // Property for adding a new SpecialCategory object if the user needs to
    @State private var addNewSpecialCat: Bool = false
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allSpecialCats: FetchedResults<SpecialCategory>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allSpecialCats.isEmpty {
                NoSpecialCatsView()
            } else {
                VStack {
                    Text("Credential: \(credential.credentialName)")
                        .font(.title)
                    List(allSpecialCats, selection: $selectedCats) { cat in
                        Button {
                            addOrRemove(category: cat)
                        } label: {
                            HStack {
                                Text(cat.specialName)
                                Spacer()
                                if selectedCats.contains(cat) {
                                    Image(systemName: "checkmark")
                                }
                            }//: HSTACK
                        }
                        
                    }//: LIST
                }//: VSTACK
                .navigationTitle("Assign Special CE Categories to Credential")
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
                    
                    // Saving the selected Special CE Categories for the credential
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            credential.specialCats = selectedCats as NSSet
                            dataController.save()
                            dismiss()
                        } label: {
                            Label("Save", systemImage: "internaldrive.fill")
                        }
                    }//: SAVE TOOLBAR ITEM
                    
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
                .sheet(isPresented: $addNewSpecialCat){
                    SpecialCategorySheet(existingCat: nil)
                }
                // MARK: - ON APPEAR
                // if any special CE categories are already assigned to the object when the sheet
                // is presented, assign those values to the @State property so the user can
                // reassign or add more as needed
                .onAppear {
                    if let cats = credential.specialCats as? Set<SpecialCategory> {
                        selectedCats = cats
                    }
                }//: ON APPEAR
            }
            
        }//: NAV VIEW
    }
    // MARK: - FUNCTIONS
    /// Adds a passed-in (selected) special category to the selectedCats array but if that value is already there then it is removed (eg. the user
    /// tapped the row again because they wanted to remove it
    /// - Parameter category: SpecialCategory object being passed in from the parent view
    func addOrRemove(category: SpecialCategory) {
        if selectedCats.contains(category) {
            selectedCats.remove(category)
        } else {
            selectedCats.insert(category)
        }
    }//: ADDorREMOVE FUNC
}

// MARK: - PREVIEW
#Preview {
    SpecialCECatAssignmentManagementSheet(credential: .example)
}

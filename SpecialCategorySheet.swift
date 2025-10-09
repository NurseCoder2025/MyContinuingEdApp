//
//  SpecialCategorySheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import SwiftUI

// Purpose: To serve as the interface from which a user can create a new special CE category or edit an existing one

struct SpecialCategorySheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // IF editing an existing special category...
    let existingCat: SpecialCategory?
    
    // Properties for each special category object
    @State private var catName: String = ""
    @State private var description: String = ""
    @State private var catAbbrev: String = ""
    @State private var hoursRequired: Double = 5.0
    
    // MARK: - BODY
    var body: some View {
        // MARK: Formmatters
        var ceHourFormat: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            
            return formatter
        }
        
        NavigationView {
            VStack {
                Form {
                    Section("Name & Abbreviation") {
                        TextField("Category Name:", text: $catName)
                        TextField("Abbreviation:", text: $catAbbrev)
                    }//: SECTION
                    
                    Section(header: Text("Details"), footer: Text("Enter how many hours you are required to obtain for activities of this category in any given renewal period.")) {
                        TextField("Description:", text: $description)
                        HStack {
                            Text("Hours Required:")
                                .bold()
                            TextField("CE Hours Required:", value: $hoursRequired, formatter: ceHourFormat)
                                .keyboardType(.decimalPad)
                        }//: HSTACK
                    }
                    
                }//: FORM
                
                // Save Button
                Button {
                    mapAndSave()
                    dismiss()
                } label: {
                    Label("Save", systemImage: "internaldrive.fill")
                }
                .buttonStyle(.borderedProminent)
                
                
            }//: VSTACK
            .navigationTitle("Special Category Info")
            // MARK: - TOOLBAR
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
            }
            // MARK: - ON APPEAR
            .onAppear {
                // Mapping existing special cat properties to UI
                // control values
                if let passedInCat = existingCat {
                    catName = passedInCat.specialName
                    catAbbrev = passedInCat.specialAbbreviation
                    description = passedInCat.specialCatDescription
                    hoursRequired = passedInCat.requiredHours
                }//: IF LET
            }//: ON APPEAR
            
        }//: NAV VIEW
    }//: BODY
    // MARK: - FUNCTIONS
    /// Function which maps each control in the UI to the corresponding property in the SpecialCategory object.  If the user is creating a new SpecialCategory (i.e.
    /// the existingCat property is nil) then a new object is created and the properties are mapped to that before calling the DataController's save function.
    func mapAndSave() {
        if let passedInCat = existingCat {
            passedInCat.name = catName
            passedInCat.catDescription = description
            passedInCat.abbreviation = catAbbrev
            passedInCat.requiredHours = hoursRequired
        } else {
            let container = dataController.container
            let context = container.viewContext
            
            let newCategory = SpecialCategory(context: context)
            newCategory.name = catName
            newCategory.catDescription = description
            newCategory.abbreviation = catAbbrev
            newCategory.requiredHours = hoursRequired
        }
        
        dataController.save()
    }//: MAP & SAVE
}

// MARK: - PREVIEW
#Preview {
    SpecialCategorySheet(existingCat: .example)
}

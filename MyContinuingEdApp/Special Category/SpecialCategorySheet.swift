//
//  SpecialCategorySheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import CoreData
import SwiftUI

// Purpose: To serve as the interface from which a user can create a new special CE category or edit an existing one

struct SpecialCategorySheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // IF editing an existing special category...
    @ObservedObject var existingCat: SpecialCategory
    
    // MARK: - CORE DATA
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Credential.name, ascending: true)]) var allCredentials: FetchedResults<Credential>
    
    
    // MARK: - BODY
    var body: some View {
        // MARK: Formmatters
        NavigationView {
            VStack {
                Form {
                    Section("Name & Abbreviation") {
                        TextField("Category Name:", text: $existingCat.specialName)
                        TextField("Abbreviation:", text: $existingCat.specialAbbreviation)
                    }//: SECTION
                    
                    Section(header: Text("Details"), footer: Text("Enter how many hours you are required to obtain for activities of this category in any given renewal period.")) {
                        TextField("Description:", text: $existingCat.specialCatDescription)
                        HStack {
                            Text("CEs Required:")
                                .bold()
                            TextField("CEs Required:", value: $existingCat.requiredHours, formatter: ceHourFormatter)
                                .keyboardType(.decimalPad)
                        }//: HSTACK
                        
                        Picker("CEs Awarded As", selection: $existingCat.measurementDefault) {
                            Text("Hours").tag(Int16(1))
                            Text("Units").tag(Int16(2))
                        }
                        .pickerStyle(.segmented)
                    }//: Section
                    
                    Section("Credential Assignment") {
                        Group {
                            VStack(alignment: .leading) {
                                Text("Select the credential that requires CE contact hours/units for this particular category.")
                                Picker("Credential", selection: $existingCat.credential) {
                                    Text("Select Credential").tag(nil as Credential?)
                                    ForEach(allCredentials) { credential in
                                        Text(credential.credentialName).tag(credential)
                                    }//: LOOP
                                }//: PICKER
                            }//: VSTACK
                            
                        }//: GROUP
                    }//: SECTION
                    
                }//: FORM
                
                
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
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Save")
                    }//: BUTTON
                }//: TOOLBAR ITEM
                
            }//: TOOLBAR
            
            // MARK: - ON APPEAR / DISAPPEAR
            .onAppear {
               
            }//: ON APPEAR
            
            .onDisappear {
                dataController.save()
            }
            // MARK: - AUTO SAVE
            .onReceive(existingCat.objectWillChange) { _ in
                dataController.queueSave()
            }
            .onSubmit {
                dataController.save()
            }
            
        }//: NAV VIEW
    }//: BODY
    // MARK: - FUNCTIONS
    
}

// MARK: - PREVIEW
#Preview {
    SpecialCategorySheet(existingCat: .example)
}

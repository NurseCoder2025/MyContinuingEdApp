//
//  RSCRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct RSCRowView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var rscItem: ReinstatementSpecialCat
    
    @State private var showInvalidSpecialCatSelectionAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property used for wrapping an object and computed property from within the object's
    /// CoreData-Helper file within a shorter name for easier reference in the view.
    var availableSpecialCats: [SpecialCategory] {
        return rscItem.specialCatsToSelectFrom
    }//: availableSpecialCats
    
    // MARK: - BODY
    var body: some View {
        // Only show the UI fields if there are special categories to choose from.
        // SpecialCategory objects are all user-created.
            // MARK: - Special Category selection & Hours
            if availableSpecialCats.isNotEmpty {
                    VStack {
                        Text("Credential-Specific CE Requirement")
                        Picker("Credential-Specific CE Requirement", selection: $rscItem.specialCat) {
                            Text(SpecialCategory.placeholder.labelText).tag(SpecialCategory.placeholder)
                            ForEach(availableSpecialCats) { specialCat in
                                Text(specialCat.labelText).tag(specialCat)
                            }//: LOOP
                        }//: Picker
                        .pickerStyle(.wheel)
                        
                        // MARK: CEs required textfield
                        HStack {
                            Text("Required CEs:")
                            Spacer()
                            TextField("CEs Required", value: $rscItem.cesRequired, formatter: ceHourFormatter)
                                .keyboardType(.decimalPad)
                                .onSubmit {
                                    dismissKeyboard()
                                }//: ON SUBMIT
                            
                        }//: HSTACK
                        
                        // MARK: Delete button
                        DeleteObjectButtonView(
                            buttonText: "Delete",
                            onDelete: {
                                dataController.delete(rscItem)
                            }
                        )
                        
                    }//: VSTACK
                    .onChange(of: rscItem.cesRequired) { _ in
                        if rscItem.specialCat == SpecialCategory.placeholder {
                            showInvalidSpecialCatSelectionAlert = true
                        }//: IF
                    }//: ON CHANGE
                    .disabled(rscItem.isDeleted)
                    // MARK: - ALERTS (Special Category Selection)
                    .alert("No Category Selected", isPresented: $showInvalidSpecialCatSelectionAlert) {
                    } message: {
                        Text("You're entering a CE requirement but you haven't selected a credential-specific CE category yet. Please do so before closing this sheet.")
                    }//: ALERT
                    
            }//: IF
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RSCRowView(rscItem: .example)
}

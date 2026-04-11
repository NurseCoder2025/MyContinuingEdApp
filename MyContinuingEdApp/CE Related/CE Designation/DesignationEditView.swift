//
//  DesignationEditView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/26/25.
//

import SwiftUI

struct DesignationEditView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    var designation: CeDesignation?
    
    // Properties for editing a designation
    @State private var desName: String = ""
    @State private var desAbbrev: String = ""
    @State private var desAKA: String = ""
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            
            VStack {
                Text("A CE designation is a label that identifies the kind of continuing education that is being awarded. Usually it is specified on the certificate, near the number of hours/units being awarded. Examples include CME (Continuing Medical Education), CLE (Continuing Legal Education), etc.")
                    .multilineTextAlignment(.leading)
                    .padding([.leading, .trailing], 15)
                
                Form {
                    // MARK: Full Name Section
                    Section("Full Name") {
                        if let existingDes = designation {
                            TextField(existingDes.ceDesignationName, text: $desName)
                        } else {
                            TextField("Designation name", text: $desName)
                        }
                    }//: SECTION
                    
                    // MARK: Name Abbreviation Section
                    Section("Name Abbreviation") {
                        if let exisitingDes = designation {
                            TextField(exisitingDes.ceDesignationAbbrev, text: $desAbbrev)
                        } else {
                            TextField("Abbreviation", text: $desAbbrev)
                        }
                    }//: SECTION
                        
                    // MARK: Alternative Term Section
                    Section {
                        if let desCur = designation {
                            TextField(desCur.ceDesignationAKA, text: $desAKA)
                        } else {
                            TextField("Similar Term", text: $desAKA)
                        }
                    } header: {
                        Text("Alternative Term")
                    } footer: {
                        Text("In some cases there may be multiple terms that refer to the same designation, such as continuing nursing education (CNE) and nursing CE, so if that's the case for your credential indicate that here.")
                        
                    }//: SECTION
                    
                }//: FORM
                
            }//: VSTACK
            .navigationTitle("Add/Edit Designation")
            // MARK: - TOOLBAR
            .toolbar {
                // Save Button
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // TODO: Add action(s)
                        mapAndSave()
                    } label: {
                        Text("Save")
                    }//: BUTTON
                }//: TOOLBAR ITEM
             
                // Dismiss Button
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                }//: TOOLBAR ITEM
                
            }//: TOOLBAR
            // MARK: - ON APPEAR
            .onAppear {
                // Preload existing designation values into fields IF editing
                // an existing one
                if let existingDesignation = designation {
                    desName = existingDesignation.ceDesignationName
                    desAbbrev = existingDesignation.ceDesignationAbbrev
                    desAKA = existingDesignation.ceDesignationAKA
                }//: IF LET
                
            }//: ON APPEAR
            
        }//: NAV VIEW
    } //: BODY
    // MARK: - FUNCTIONS
    func mapAndSave() {
        if designation == nil {
            let newDes = CeDesignation(context: dataController.container.viewContext)
            newDes.designationName = desName
            newDes.designationAbbreviation = desAbbrev
            newDes.designationAKA = desAKA
            
            dataController.save()
        } else {
            designation?.ceDesignationName = desName
            designation?.ceDesignationAbbrev = desAbbrev
            designation?.designationAKA = desAKA
            
            dataController.save()
        }
        
        dismiss()
    }
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    DesignationEditView(designation: .example)
        .environmentObject(DataController(inMemory: true))
}

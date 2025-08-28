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
                    .padding([.leading, .trailing], 10)
                
                Form {
                    Section("Full Name") {
                        if let existingDes = designation {
                            TextField(existingDes.ceDesignationName, text: $desName)
                        } else {
                            TextField("Designation name", text: $desName)
                        }
                    }
                    
                    Section("Name Abbreviation") {
                        if let exisitingDes = designation {
                            TextField(exisitingDes.ceDesignationAbbrev, text: $desAbbrev)
                        } else {
                            TextField("Abbreviation", text: $desAbbrev)
                        }
                    }
                        
                        Section("Alternative Term") {
                            if let desCur = designation {
                                TextField(desCur.ceDesignationAKA, text: $desAKA)
                            } else {
                                TextField("Similar Term", text: $desAKA)
                            }
                        }
                    
                }//: FORM
                
                Button {
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
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                
            }//: VSTACK
            .navigationTitle("Add/Edit Designation")
            
        }//: NAV VIEW
    }
}

// MARK: - PREVIEW
#Preview {
    DesignationEditView(designation: .example)
}

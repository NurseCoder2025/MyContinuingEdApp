//
//  ReinstatementInfoView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct ReinstatementInfoSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var reinstatement: ReinstatementInfo
    
    @State private var showSpecialCatManagementSheet: Bool = false
    @State private var showDeleteRIAlert: Bool = false
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                // MARK: DISMISS
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                    Spacer()
                }//: HSTACK
                .padding(.leading, 20)
                // MARK: - FORM
                Form {
                    // Fees & Deadline Info
                    FeeAndDeadlineView(reinstatement: reinstatement)
                    
                    // CE Requirements
                    CeRequirementsView(reinstatement: reinstatement) {
                        showSpecialCatManagementSheet = true
                    }
                    
                    // Documentation needed
                    ReinstatementDocumentationView(reinstatement: reinstatement)
                    
                    // Additional items (background check, interview, test)
                    ReinstatementAdditionalItemsView(reinstatement: reinstatement)
                    
                    // MARK: - DELETE
                    Section("Delete") {
                        DeleteObjectButtonView(
                            buttonText: "Delete Reinstatement",
                            onDelete: {showDeleteRIAlert = true}
                        )
                    }//: SECTION
                    
                }//: FORM
                .disabled(reinstatement.isDeleted)
            }//: VSTACK
            .navigationTitle("Reinstatement Information")
            .navigationBarTitleDisplayMode( .inline)
            

        }//: NAV VIEW
        // MARK: - SHEETS
        .sheet(isPresented: $showSpecialCatManagementSheet) {
            if let cred = reinstatement.lapsedCredential {
                SpecialCECatsManagementSheet(dataController: dataController, credential: cred)
            }//: IF LET
        }//: SHEET
        // MARK: - ALERTS
        .alert("Delete Reinstatement?", isPresented: $showDeleteRIAlert) {
            Button("Cancel", role: .cancel){}
            Button("Delete", role: .destructive) {
                deleteReinstatement()
            }
        } message: {
            Text("Are you sure you wish to remove reinstatement information for this renewal period?")
        }
        // MARK: - AUTO SAVE
        // This allows for the auto-saving of changes to any
        // reinstatementInfo properties that are changed by the user
        .onReceive(reinstatement.objectWillChange) { _ in
            dataController.queueSave()
        }//: ON RECIEVE
        
        .onSubmit {
            dataController.save()
        }//: ON SUBMiT
        
    }//: BODY
     // MARK: - METHODS
    
    /// View method that deletes the ReinstatementInfo object that is being shown to
    /// the user after they confirm deletion with the pop-up alert message. Sheet is then
    /// dismissed.
    func deleteReinstatement() {
        dataController.delete(reinstatement)
        dismiss()
    }//: deleteReinstatement()
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ReinstatementInfoSheet(reinstatement: .example)
}

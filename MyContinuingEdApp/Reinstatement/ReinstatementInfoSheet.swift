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
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button {
                        // TODO: Add action(s)
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                    Spacer()
                }//: HSTACK
                .padding(.leading, 20)
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
                    
                }//: FORM
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
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ReinstatementInfoSheet(reinstatement: .example)
}

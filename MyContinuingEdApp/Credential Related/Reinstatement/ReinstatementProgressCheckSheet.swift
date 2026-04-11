//
//  ReinstatementProgressCheckSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/12/26.
//

import SwiftUI

struct ReinstatementProgressCheckSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @ObservedObject var reinstatement: ReinstatementInfo
    
    @State private var reinstateRequiredCes: Double = 1.0
    @State private var reinstateEarnedCes: Double = 0.0
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Form {
                ReinstatementCEProgressView(
                    reinstatement: reinstatement,
                    requiredHours: reinstateRequiredCes,
                    earnedHours: reinstateEarnedCes
                )
            }//: FORM
        }//: VSTACK
        .navigationTitle("Reinstatement Progress")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - TOOLBAR
        .toolbar {
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
            if let renewal = reinstatement.renewal {
                let updatedCEs = dataController.calculateCEsForReinstatement(renewal: renewal)
                reinstateRequiredCes = updatedCEs.required
                reinstateEarnedCes = updatedCEs.earned
            }//: IF LET
        }//: ON APPEAR
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    ReinstatementProgressCheckSheet(reinstatement: .example)
}

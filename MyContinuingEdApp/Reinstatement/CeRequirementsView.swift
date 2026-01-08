//
//  CeRequirementsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct CeRequirementsView: View {
    // MARK: - PROPERTIES
    @ObservedObject var reinstatement: ReinstatementInfo
    // MARK: - BODY
    var body: some View {
        Section("Required Continuing Education") {
            HStack {
                Text("Total Extra Hours Required:")
                    .bold()
                
                TextField(
                    "CEs Required",
                    value: $reinstatement.totalExtraCEs,
                    formatter: ceHourFormatter
                )//: TEXTFIELD
                .keyboardType(.decimalPad)
                .onSubmit {
                    dismissKeyboard()
                }//: ON SUBMIT
            }//: HSTACK
        }//: SECTION
        
        Section("Credential-Specific CE Requirements") {
            
        }//: SECTION
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CeRequirementsView(reinstatement: .example)
}

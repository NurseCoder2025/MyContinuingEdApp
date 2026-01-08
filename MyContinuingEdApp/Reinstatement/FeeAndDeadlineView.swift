//
//  FeeAndDeadlineView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct FeeAndDeadlineView: View {
    // MARK: - PROPERTIES
    @ObservedObject var reinstatement: ReinstatementInfo
    // MARK: - BODY
    var body: some View {
        Section("Fee & Deadline Info") {
            HStack {
                Text("Reinstatement Fee:")
                    .bold()
                
                TextField(
                    "Reinstatement Fee",
                    value: $reinstatement.reinstatementFee,
                    formatter: currencyFormatter
                )//: TEXTFIELD
                .keyboardType(.decimalPad)
                .onSubmit {
                    dismissKeyboard()
                }//: ON SUBMIT
            }//: HSTACK
            
            DatePicker(
                "Reinstatement Deadline",
                selection: $reinstatement.riDeadline,
                displayedComponents: .date
            )//: DATEPICKER
            
        }//: SECTION
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    FeeAndDeadlineView(reinstatement: .example)
}

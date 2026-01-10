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
        Section {
            HStack(spacing: 75) {
                Text("Reinstatement Fee:")
                    .bold()
                    .multilineTextAlignment(.leading)
                TextField(
                    "Reinstatement Fee",
                    value: $reinstatement.reinstatementFee,
                    formatter: currencyFormatter
                )//: TEXTFIELD
                .frame(maxWidth: 50)
                .keyboardType(.decimalPad)
                .onSubmit {
                    dismissKeyboard()
                }//: ON SUBMIT
            }//: HSTACK
            .frame(maxWidth: .infinity, alignment: .leading)
            
            DatePicker(
                "Reinstatement Deadline",
                selection: $reinstatement.riDeadline,
                displayedComponents: .date
            )//: DATEPICKER
            
        } header: {
            Text("Fee & Deadline Info")
        } footer: {
            Text("If your credential's governing body doesn't set a reinstatement deadline for you, then you can enter a date when you want to complete the reinstatement process. Ce Cache will remind you of this date.")
        }//: SECTION
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    FeeAndDeadlineView(reinstatement: .example)
}

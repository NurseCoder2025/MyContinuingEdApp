//
//  CredentialIssueAndRenewalSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for the Credential object's issuance and renewal section
// properties

// 10-13-25 update: replaced @State property with single @ObservableObject credential

import SwiftUI

struct CredentialIssueAndRenewalSectionView: View {
    // MARK: - PROPERTIES
    @ObservedObject var credential: Credential
    
    // MARK: - BODY
    var body: some View {
        Section {
            // MARK: Issued Date
            DatePicker("Issued On", selection: Binding(
                get: {credential.issueDate ?? Date.now},
                set: {credential.issueDate = $0}
            ), displayedComponents: [.date])
            .accessibilityHint(Text("Enter the date on which your credential was originally issued to you.  You can also use the current date if you don't know the exact date. Renewals are tracked separately and if none exist, you can set them up in the sidebar or below with the add renewal button."))
            
            // MARK: Renewal Period Length
            HStack(spacing: 4) {
                Label("Renews every: ", systemImage: "calendar.badge.clock").accessibilityHidden(true)
                TextField(
                    "Renews in months",
                    value: $credential.renewalPeriodLength,
                    formatter: singleDecimalFormatter
                )
                    .frame(maxWidth: 25)
                    .bold()
                    .foregroundStyle(.red)
                    .keyboardType(.decimalPad)
                    .submitLabel(.done)
                    .onSubmit {
                        dismissKeyboard()
                    }
                Text("months")
            }//: HSTACK
            
            // MARK: Required CE hours for each renewal
            HStack {
                Label("CEs Required: ", systemImage: "number.square.fill").accessibilityHidden(true)
                TextField(
                    "Required CE hours",
                    value: $credential.renewalCEsRequired,
                    formatter: twoDigitDecimalFormatter
                )
                .frame(maxWidth: 45)
                .bold()
                .foregroundStyle(.blue)
                .keyboardType(.decimalPad)
                .submitLabel(.done)
                .onSubmit {
                    dismissKeyboard()
                }
                .accessibilityHint(Text("Enter the number of CEs required to renew this credential each renewal period."))
                Text("\(credential.measurementDefault == Int16(1) ? "hours" : "units")")
                
            }//: HSTACK
            
        } header: {
            Text("Issue & Renewal")
        } footer: {
            Text("When was your credential originally issued?  How often does it need to be renewed?  How many CEs in total do you need to complete each renewal - enter the number in terms of your preferred unit (hours or units)?")
                
        }//: SECTION
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialIssueAndRenewalSectionView(credential: .example)
}

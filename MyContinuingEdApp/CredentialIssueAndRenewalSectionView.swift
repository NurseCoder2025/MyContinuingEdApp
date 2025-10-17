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
            
            // MARK: Renewal Period Length
            HStack(spacing: 4) {
                Label("Renews every: ", systemImage: "calendar.badge.clock")
                TextField(
                    "Renews in months",
                    value: $credential.renewalPeriodLength,
                    formatter: singleDecimalFormatter
                )
                    .frame(maxWidth: 25)
                    .bold()
                    .foregroundStyle(.red)
                Text("months")
            }//: HSTACK
            
        } header: {
            Text("Issue & Renewal")
        } footer: {
            Text("Enter the date on which the credential was originally issued.  Specify the renewal period in months (e.g., 24 months = 2 years). Each renewal period will keep track of subsequent renewals for this credential.")
                
        }//: SECTION
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialIssueAndRenewalSectionView(credential: .example)
}

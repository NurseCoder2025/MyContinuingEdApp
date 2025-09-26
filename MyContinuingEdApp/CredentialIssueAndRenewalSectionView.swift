//
//  CredentialIssueAndRenewalSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for the Credential object's issuance and renewal section
// properties

import SwiftUI

struct CredentialIssueAndRenewalSectionView: View {
    // MARK: - PROPERTIES
    
    // Credential property from parent view
    let credential: Credential?
    
    // Binding properties to parent view
    @Binding var renewalLength: Double
    
    
    // MARK: - BODY
    var body: some View {
        Section("Issue & Renewal") {
            // MARK: Issued Date
            DatePicker("Issued On", selection: Binding(
                get: {credential?.issueDate ?? Date.now},
                set: {credential?.issueDate = $0}
            ), displayedComponents: [.date])
            
            // MARK: Renewal Period Length
            HStack(spacing: 4) {
                Label("Renews every: ", systemImage: "calendar.badge.clock")
                TextField("Renews in months", value: $renewalLength, formatter: singleDecimalFormatter )
                    .frame(maxWidth: 25)
                    .bold()
                    .foregroundStyle(.red)
                Text("months")
            }//: HSTACK
            
        }//: SECTION
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialIssueAndRenewalSectionView(credential: .example, renewalLength: .constant(24.0))
}

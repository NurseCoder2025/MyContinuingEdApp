//
//  CredentialListRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/30/26.
//

import SwiftUI

struct CredentialListRowView: View {
    // MARK: - PROPERTIES
    @ObservedObject var credential: Credential
    
    let isSelected: Bool
    // MARK: - BODY
    var body: some View {
        VStack(alignment: .center) {
            HStack(spacing: 5){
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color(.green))
                        .accessibilityLabel(Text("The \(credential.credentialName) has been selected"))
                }//: IF (isSelected)
                
                Spacer()
                Text(credential.credentialName)
                    .font(.headline)
                
                if let expDate = credential.expirationDate {
                    Text(expDate, style: .date)
                        .font(.caption)
                        .accessibilityLabel(Text("Your \(credential.credentialName) expires on \(expDate)"))
                }//: IF LET (expDate)
                Spacer()
            }//: HSTACK
            
            HStack(alignment: .center, spacing: 10) {
                Spacer()
                Text("Renewals: \(credential.allRenewals.count)")
                    .font(.subheadline)
                    .accessibilityLabel(Text("You currently have \(credential.allRenewals.count) renewal periods saved for your \(credential.credentialName)."))
                
                if credential.isRestricted {
                    Spacer()
                    Text("RESTRICTED")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(Color.red)
                        .accessibilityLabel(Text("Your \(credential.credentialName) is currently has restrictions imposed upon it."))
                }//: IF (isRestricted)
                Spacer()
            }//: HSTACK
            
        }//: VSTACK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CredentialListRowView(credential: .example, isSelected: true)
}

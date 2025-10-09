//
//  BasicCredentialInfoView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 10/09/2025.
//

// Purpose: To notify the user that no credentials are currently saved in persistent storage
// and to provide a button for adding a credential.

import SwiftUI

struct NoCredentialsView: View {
    // MARK: - PROPERTIES
    
    // Property to toggle the CredentialSheet for adding a new credential
    @State private var showCredentialSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        Group {
            Button {
                // TODO: Add action(s)
                showCredentialSheet = true
            } label: {
                Label("Add Credential", systemImage: "person.text.rectangle.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }//: BUTTON
            .buttonStyle(.borderedProminent)
        }//: GROUP
         // MARK: - SHEETS
             .sheet(isPresented: $showCredentialSheet) {
                 CredentialSheet(credential: nil)
             }
        
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    NoCredentialsView()
}

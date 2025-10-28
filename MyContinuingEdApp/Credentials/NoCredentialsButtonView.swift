//
//  BasicCredentialInfoView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 10/09/2025.
//

// Purpose: To notify the user that no credentials are currently saved in persistent storage
// and to provide a button for adding a credential.

// 10-28-25: Updated button so that it passes a closure up to the parent view for creating
// a new Credential object as well as showing the sheet.  This change makes the code more reusable.

import SwiftUI

struct NoCredentialsButtonView: View {
    // MARK: - CLOSURES
    var createNewCredential: () -> Void
    
    // MARK: - BODY
    var body: some View {
        Group {
            Button {
              createNewCredential()
            } label: {
                Label("Add Credential", systemImage: "person.text.rectangle.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }//: BUTTON
            .buttonStyle(.borderedProminent)
        }//: GROUP
         
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    NoCredentialsButtonView(createNewCredential: {})
}

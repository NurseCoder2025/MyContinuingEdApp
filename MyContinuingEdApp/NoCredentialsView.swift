//
//  NoCredentialsView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/9/25.
//

import SwiftUI

// Purpose of this file is to display a button whenever no credentials are stored in persistent
// storage (ex. first run of app or user deletion of all credentials).

struct NoCredentialsView: View {
    // MARK: - PROPERTIES
    @State private var showCredentialSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Button {
                showCredentialSheet = true
            } label: {
                Label("Add Credential", systemImage: "person.text.rectangle.fill")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }//: HSTACK
        .sheet(isPresented: $showCredentialSheet) {
            CredentialSheet(credential: nil)
        }
    }
        
}

// MARK: - PREVIEW
#Preview {
    NoCredentialsView()
}

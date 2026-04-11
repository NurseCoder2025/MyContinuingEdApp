//
//  CredentialRestrictionsSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for properties related to a Credential's restrictions
// from within the parent view (CredentialSheet).

// 10-13-25 update: replaced @State local properties with @ObservedObject credential from parent

import SwiftUI

struct CredentialRestrictionsSectionView: View {
    // MARK: - PROPERTIES
    
    @ObservedObject var credential: Credential
    
    // MARK: - BODY
    var body: some View {
        Section("Credential Restrictions"){
            Toggle("Any Restrictions?", isOn: $credential.isRestricted)
            
            // Details for any restrictions IF true
            if credential.isRestricted {
                TextField("Restriction details:", text: $credential.credentialRestrictions)
            }
        }//: SECTION
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialRestrictionsSectionView(credential: .example)
    
}

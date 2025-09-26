//
//  CredentialRestrictionsSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for properties related to a Credential's restrictions
// from within the parent view (CredentialSheet).

import SwiftUI

struct CredentialRestrictionsSectionView: View {
    // MARK: - PROPERTIES
    
    // Needed properties
    // - restrictedYN (Bool)
    // - restrictionsDetails (String)
    
    // Binding properties to the parent view
    @Binding var restrictedYN: Bool
    @Binding var restrictionsDetails: String
    
    // MARK: - BODY
    var body: some View {
        Section("Credential Restrictions"){
            Toggle("Any Restrictions?", isOn: $restrictedYN)
            
            // Details for any restrictions IF true
            if restrictedYN {
                TextField("Restriction details:", text: $restrictionsDetails)
            }
        }//: SECTION
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialRestrictionsSectionView(
        restrictedYN: .constant(false),
        restrictionsDetails: .constant("N/A")
    )
}

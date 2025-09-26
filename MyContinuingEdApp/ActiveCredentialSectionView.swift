//
//  ActiveCredentialSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI Controls for indicating whether a given Credential object is
// currently active or not

import SwiftUI

struct ActiveCredentialSectionView: View {
    // MARK: - PROPERTIES
    
    // Needed properties/bindings
    // - activeYN (Bool)
    // - whyInactive (String)
    
    @Binding var activeYN: Bool
    @Binding var whyInactive: String
    
    // MARK: - BODY
    var body: some View {
        // MARK: ACTIVE Y or N?
        Group {
            Section {
                Toggle("Credential Active?", isOn: $activeYN)
                
                // ONLY show the following fields if credential is inactive
                if activeYN == false {
                    Text("Why Is the Credential Inactive?")
                    Picker("Inactive Reason", selection: $whyInactive) {
                        ForEach(InactiveReasons.defaultReasons) { reason in
                            Text(reason.reasonName).tag(reason.reasonName)
                        }//: LOOP
                    }//: PICKER
                    .pickerStyle(.wheel)
                    .frame(height:100)
                }
            }//: SECTION
        }//: GROUP
        // MARK: - ON CHANGE
        // If the user changes the credential active switch to true from
        // false, reset the inactiveReason property to an empty string.
        .onChange(of: activeYN) { _ in
            if activeYN == true {
                whyInactive = ""
            }
        }//: ON CHANGE OF
    }
}

// MARK: - PREVIEW
#Preview {
    ActiveCredentialSectionView(activeYN: .constant(true), whyInactive: .constant("No reason"))
}

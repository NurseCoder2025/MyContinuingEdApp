//
//  ActiveCredentialSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI Controls for indicating whether a given Credential object is
// currently active or not

// 10-13-25 update: Replaced @State properties with a single @ObservedObject property (credential)

import SwiftUI

struct ActiveCredentialSectionView: View {
    // MARK: - PROPERTIES
    
    @ObservedObject var credential: Credential
    
    // MARK: - BODY
    var body: some View {
        // MARK: ACTIVE Y or N?
        Group {
            Section {
                Toggle("Credential Active?", isOn: $credential.isActive)
                
                // ONLY show the following fields if credential is inactive
                if credential.isActive == false {
                    Text("Why Is the Credential Inactive?")
                    Picker("Inactive Reason", selection: $credential.inactiveReason) {
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
        .onChange(of: credential.isActive) { _ in
            if credential.isActive == true {
                credential.inactiveReason = ""
            }
        }//: ON CHANGE OF
    }
}

// MARK: - PREVIEW
#Preview {
    ActiveCredentialSectionView(credential: .example)
}

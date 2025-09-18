//
//  CredentialSelectionPopOver.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/18/25.
//

// Purpose: To allow the user to select a Credential object from within ActivityView in order to add
// a SpecialCategory object to the Credential. This is only needed if the CE activity being added
// is for a specific, required category that the licensing or governing body requires for all credential
// holders, such as ethics. If the user hasn't previously added a SpecialCategory object to the
// respective credential then they can do so from within this popover in ActivityView.


import SwiftUI

struct CredentialSelectionPopOver: View {
    // MARK: - PREVIEW
    @Environment(\.dismiss) var dismiss
    
    let activity: CeActivity // reading from the CeActivity object being passed in
    @Binding var selectedCredential: Credential? // writing out to the selectedCredential property from parent
    @Binding var showCredentialSelectionPopover: Bool
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text("Select Credential")
                .font(.title)
                .multilineTextAlignment(.leading)
            
            Text("Choose a credential for adding special CE categories to.")
                .multilineTextAlignment(.leading)
            
            Picker("Credential", selection: $selectedCredential) {
                ForEach(activity.activityCredentials) { cred in
                    Text(cred.credentialName).tag(cred)
                }//: LOOP
            }//: PICKER
            
            Button {
                showCredentialSelectionPopover = false
                dismiss()
            } label: {
                Text("Confirm Selection")
            }
            .buttonStyle(.borderedProminent)
            
        }//: VSTACK
    }
}

// MARK: - PREVIEW
#Preview {
    CredentialSelectionPopOver(activity: .example, selectedCredential: .constant(.example), showCredentialSelectionPopover: .constant(false))
}

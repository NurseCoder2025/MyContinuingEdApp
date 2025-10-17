//
//  NoCredSubTypeView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/7/25.
//

// Purpose: To inform the user that no credentials for a given subtype have been
// entered into the app yet.

import SwiftUI

struct NoCredSubTypeView: View {
    //: MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Passed-in String indicating the credential type
    // This value is passed in as a singular variant of the CredentialType enum raw value
    let credentialType: String
    
    // Binding to show the CredentialSheet when the user taps the button
    @State private var showCredSheet: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    // Heading and body message strings based on the credential type
    var headingText: String {
        if credentialType.isEmpty {
            return "No Credentials Saved"
        } else if credentialType == "all" {
            return "No Credentials Saved"
        } else if credentialType == "other" {
            return "No Other Credentials Saved"
        } else {
            return "No \(credentialType.capitalized)s Saved"
        }
    }//: HEADING TEXT
    
    var bodyText: String {
        if credentialType.isEmpty {
            return "Currently there are no credentials saved yet. Please add a credential using the button below."
        } else if credentialType == "all" {
            return "Currently there are no credentials saved yet. Please add a credential using the button below."
        } else if credentialType == "other" {
            return """
            Currently there are no other kinds of credentials saved yet.
            If you possess a credential that is not a license, certification,
            endorsement, or membership, then please add it using the button below.
            """
        } else {
            return "Currently there are no \(credentialType)s saved yet. If you have credentials of this type, please add them using the button below."
        }
    }
    
    //: MARK: - BODY
    var body: some View {
        VStack {
            #if debug
            // Debug: Show credentialType value
            Text("credentialType: \(credentialType)")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top, 4)
            #endif // debug
            
            // Dismiss button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Dismiss")
                }//: BUTTON
                .padding(.leading, 20)
                .padding(.top, 20)
                
                Spacer()
            }//: HSTACK
            
            Spacer()
            
            Group {
                VStack {
                    Image(systemName: "slash.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    
                    Text(headingText)
                        .font(.title2)
                        .padding([.top, .bottom], 5)
                    
                    Text(bodyText)
                        .multilineTextAlignment(.leading)
                        .padding([.leading, .trailing], 42.5)
                }//: VSTACK
                .padding(.bottom, 10)
                
                Button {
                    // Action
                    showCredSheet = true
                } label: {
                    Label(
                        "Add \(credentialType == "all" ? "credential" : credentialType)",
                        systemImage: "plus.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
            }//: GROUP
            
            Spacer()
            
        }//: VSTACK
        
        //: MARK: - SHEETS
        .sheet(isPresented: $showCredSheet) {
            let newCred = createNewCredWithType(type: credentialType)
            CredentialSheet(credential: newCred)
        }
    } //: BODY
    
    //: MARK: - FUNCTIONS
    
    func createNewCredWithType(type: String) -> Credential {
        let newCred = dataController.createNewCredential()
        newCred.credentialType = credentialType
        return newCred
    }
    
} //: STRUCT


//: MARK: - PREVIEW
#Preview {
    NoCredSubTypeView(credentialType: "license")
}

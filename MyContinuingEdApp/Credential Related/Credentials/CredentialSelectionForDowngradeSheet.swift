//
//  CredentialSelectionForDowngradeSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/30/26.
//

import CoreData
import SwiftUI

struct CredentialSelectionForDowngradeSheet: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedCredToKeep: Credential?
    
    @State private var potentialCredential: Credential? = nil
    @State private var showCredSelectionConfirmation: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var credentialName: String {
        potentialCredential?.credentialName ?? "Unselected"
    }//: credentialName
    
    // MARK: - CORE DATA
    @FetchRequest(
        entity: Credential.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        ) var credentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text("Because you downgraded from CE Cache Pro to CE Cache Core or Free, you can only keep a single credential. Since you have more than one, please select the credential you wish to keep. All others will be permanently deleted.")
                .multilineTextAlignment(.leading)
            
            Text("Note: This will not affect any of the CE activities previously associated to the credentials that will be deleted. They will remain saved on your device but may not appear under the selected credential's renewal periods until you re-assign them to that credential.")
                .font(.caption)
                .multilineTextAlignment(.leading)
            
            Divider()
            
            List {
                ForEach(credentials) { cred  in
                    CredentialListRowView(
                        credential: cred,
                        isSelected: (potentialCredential == cred)
                    )//: CredentailListRowView
                    .contentShape(Rectangle())
                    .onTapGesture {
                        potentialCredential = cred
                    }//: ON TAP
                }//: LOOP
            }//: LIST
        }//: VSTACK
        .navigationTitle(Text("Choose a Credential to Keep"))
        // MARK: - TOOLBARS
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Choose") {
                    showCredSelectionConfirmation = true
                }//: BUTTON (choose)
            }//: TOOLBAR ITEM
        }//: TOOLBAR
        // MARK: - CONFIRMATION DIALOG
        .confirmationDialog("Confirm Choice", isPresented: $showCredSelectionConfirmation) {
            Button("Confirm", role: .destructive) {
                selectedCredToKeep = potentialCredential
                dismiss()
            }//: BUTTON (confirm)
            Button("Cancel", role: .cancel) {}//: BUTTON (cancel)
        } message: {
            Text("You seletected \(credentialName) as the credential you wish to keep. Are you sure? Once confirmed, all other credential objects will be permanently deleted.")
        }//: CONFIRMATION DIALOG
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CredentialSelectionForDowngradeSheet(selectedCredToKeep: .constant(nil))
}

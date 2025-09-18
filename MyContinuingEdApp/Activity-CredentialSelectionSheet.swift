//
//  Activity-CredentialSelectionSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/17/25.
//

// Purpose: To allow the user to select one or more Credentials for which a CeActivity is being
// applied to

import CoreData
import SwiftUI

struct Activity_CredentialSelectionSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Passing in the CeActivity object for which the credentials will be assigned to
    @ObservedObject var activity: CeActivity
    
    // Credential objects that the user wants to assign to the activity
    @State private var selectedCredentials: Set<Credential> = []
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allCredentials.isEmpty {
                NoCredentialsView()
            } else {
                List(allCredentials, selection: $selectedCredentials) { credential in
                    Button {
                        if selectedCredentials.contains(credential) {
                            selectedCredentials.remove(credential)
                        } else {
                            selectedCredentials.insert(credential)
                        }
                    } label: {
                        HStack {
                            Text(credential.credentialName)
                            Spacer()
                            if selectedCredentials.contains(credential ) {
                                Image(systemName: "checkmark")
                            }
                        }//: HSTACK
                    }
                }//: LIST
                .navigationTitle("Select Credential(s)")
                // MARK: - TOOLBAR
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            activity.credential = selectedCredentials as NSSet
                            dataController.save()
                            dismiss()
                        } label: {
                            Label("Save", systemImage: "internaldrive.fill")
                        }
                    }//: TOOLBAR ITEM (save)
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "clear.fill")
                        }
                    }//: TOOLBAR ITEM
                }
                
                // MARK: - ON APPEAR
                // if any credentials have already been assigned to an activity when
                // this sheet is pulled up, then assign those values to the
                // @State property so that the user can modify as desired
                .onAppear {
                    if let creds = activity.credential as? Set<Credential> {
                        selectedCredentials = creds
                    }
                }//: ON APPEAR
            }
            
        }//: NAV VIEW
    }
}

// MARK: - PREVIEW
#Preview {
    Activity_CredentialSelectionSheet(activity: .example)
}

//
//  EncumberedCredentialListSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/7/25.
//

// Purpose: To display a sheet with a list of encumbered credentials
// that the user wants to see from the CredentialManagementSheet

import SwiftUI

struct EncumberedCredentialListSheet: View {
    //: MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    
    //: MARK: - COMPUTED PROPERTIES
   // Getting an array of any encumbered credential objects, as determined by
   // the getEncumberedCredentials() method in the DataController class
    var allEncumberedCredentials: [Credential] {
        dataController.getEncumberedCredentials()
    }
    
    
    
    //: MARK: - BODY
    var body: some View {
        NavigationView {
            Group {
                if allEncumberedCredentials.isEmpty {
                    VStack {
                        NoEncumberedCredsView()
                        Spacer()
                    }//: VSTACK
                } else {
                    // MARK: LIST
                    List {
                        ForEach(allEncumberedCredentials) { cred in
                            NavigationLink {
                                CredentialSheet(credential: cred)
                            } label: {
                                Text(cred.credentialName)
                            }//: NAV LINK
                            
                        }//: LOOP
                        
                    }//: LIST
                    
                }//: IF-ELSE
                
            }//: GROUP
            //: MARK: - TOOLBAR
            .toolbar {
                // MARK: Custom Title
                ToolbarItem(placement: .principal) {
                        Text("Encumbered Credentials")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    
                } //: TOOLBAR ITEM
            
                
            }//: TOOLBAR
            .navigationBarTitleDisplayMode(.inline)
        }//: NAV VIEW
    }//: BODY
}//: STRUCT

//: MARK: - PREVIEW
#Preview {
    EncumberedCredentialListSheet()
        .environmentObject(DataController(inMemory: true))
}

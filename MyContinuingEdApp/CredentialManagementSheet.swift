//
//  CredentialManagementSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/6/25.
//

// Purpose: To display all saved credential objects and the UI controls for adding,
// editing, and deleting them.  Also, this sheet will group the Credentials by
// encumberance status, in-state/out-of-state (local/foreign), and type
// (static allTypes property in the Core-DateHelper file for Credential)

import SwiftUI

struct CredentialManagementSheet: View {
    //: MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Property to pull up the CredentialSheet for adding a new credential
    @State private var showAddCredentialSheet: Bool = false
    
    // Property to store a newly created Credential object
    @State private var newCredential: Credential?
    
    // Property to show the CredentialSubCatListSheet as a pop-up
    @State private var showCredSubCatListSheet: Bool = false
    
    // Property to hold the selected credential subcategory
    @State private var selectedCat: CredentialCatWrapper? = nil
    
    //: MARK: - COMPUTED PROPERTIES
    // Computed property returning array of Grid items for the credential
    // category grid
    var columns: [GridItem] {
        [GridItem(.fixed(150)),
         GridItem(.fixed(150))
        ]
    }
    
    
    /// Returning any encumbered credentials as determined by the getEncumberedCredentials() method
    /// in the Data Controller class.  Will be used to determine whether to show a navigation link to the
    /// EncumberedCredentialListSheet or not.
    var encumberedCreds: [Credential] {
        dataController.getEncumberedCredentials()
    }
        
    
    //: MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    // MARK: Credential Category Grid View
                    LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                        // See the Enums-General file for the enum definition (CredentialType)
                        // Need to show the "All" category for this grid, so using allCases
                        ForEach(CredentialType.addableTypes, id: \.self) { type in
                            Button {
                                selectedCat = CredentialCatWrapper(
                                    value: type.rawValue
                                )
                            } label: {
                                CredentialCatBoxView(
                                    icon: type.typeIcon,
                                    text: type.displayPluralName,
                                    badgeCount: getCatBadgeCount(category: type.rawValue)
                                )
                            }//: BUTTON
                        }//: LOOP
                    }//: GRID
                    Spacer()
                }//: HSTACK
                
                
                // MARK: Encumberance status view
                // Navigation link to EncumberedCredentialListSheet IF there are
                // encumbered credentials
                if encumberedCreds.isNotEmpty {
                    NavigationLink {
                        EncumberedCredentialListSheet()
                    } label: {
                        // TODO: Enhance this view to make it more prominent
                        Text("Encumbered Credentials (\(encumberedCreds.count))")
                            .foregroundStyle(.red)
                    }
                }//: IF
                
                
                // In-state/Out-of-state view
                
                Spacer()
                
            }//: VSTACK
            .navigationTitle("Credentials")
            //: MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newCredential = dataController.createNewCredential()
                        showAddCredentialSheet = true
                    } label: {
                        Label("Add Credential", systemImage: "plus")
                    }
                }//: TOOLBAR ITEM
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
                    
            }//: TOOLBAR
            //: MARK: - SHEETS
            // For adding a new Credential
            .sheet(isPresented: $showAddCredentialSheet) {
                if let cred = newCredential {
                    CredentialSheet(credential: cred)
                        .onDisappear {
                            if cred.name == "New Credential" {
                                dataController.delete(cred)
                            }//: IF
                            
                        }//: ON DISAPPEAR
                }//: IF LET
                
            }//: SHEET
            
            // For showing the list of credentials of the selected type
            .sheet(item: $selectedCat) { cat in
                CredentialSubCatListSheet(credentialType: cat.value)
            }//: SHEET
            
        }//: NAV VIEW
    } //: BODY
    
    //: MARK: - FUNCTIONS
    /// Function takes in a String which represents one of the CategoryType enum raw values (see Enums-General file for details)
    /// and calls the data controller's getNumberOfCredTypes method on that string to return an integer value from the fetch request
    /// that the method uses.
    /// - Parameter category: String value representing one of the CategoryType raw values
    /// - Returns: Number of Credential objects with that matching category value
    func getCatBadgeCount(category: String) -> Int {
        let count = dataController.getNumberOfCredTypes(type: category)
        return count
    }
    
    
}//: STRUCT


//: MARK: - PREVIEW
#Preview {
    CredentialManagementSheet()
        .environmentObject(DataController(inMemory: true))
}


// MARK: - Custom Wrapper Struct for passing String to sheet
/// The purpose of this stuct is to allow the passing of a string binding value (selectedCat) to
/// a sheet.  SwiftUI sheets do not accept simple types like String, Int, etc.
struct CredentialCatWrapper: Identifiable {
    var id: String { value }
    let value: String
}

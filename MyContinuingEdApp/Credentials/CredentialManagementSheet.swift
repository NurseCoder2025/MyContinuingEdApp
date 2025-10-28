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
    
    @StateObject private var viewModel: ViewModel
    
    //: MARK: - COMPUTED PROPERTIES
    // Computed property returning array of Grid items for the credential
    // category grid
    var columns: [GridItem] {
        [GridItem(.fixed(150)),
         GridItem(.fixed(150))
        ]
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
                        ForEach(CredentialType.addableTypes, id: \.self) { type in
                            Button {
                                viewModel.selectedCat = CredentialCatWrapper(
                                    value: type.rawValue
                                )
                            } label: {
                                CredentialCatBoxView(
                                    icon: type.typeIcon,
                                    text: type.displayPluralName,
                                    badgeCount: viewModel.getCatBadgeCount(category: type.rawValue)
                                )
                                .accessibilityElement()
                                .accessibilityLabel("\(type.displayPluralName)")
                                .accessibilityHint("^[\(viewModel.getCatBadgeCount(category: type.rawValue)) \(type.rawValue)] (inflect: true)")
                            }//: BUTTON
                        }//: LOOP
                    }//: GRID
                    Spacer()
                }//: HSTACK
                
                
                // MARK: Encumberance status view
                // Navigation link to EncumberedCredentialListSheet IF there are
                // encumbered credentials
                if viewModel.encumberedCreds.isNotEmpty {
                    NavigationLink {
                        EncumberedCredentialListSheet()
                    } label: {
                        // TODO: Enhance this view to make it more prominent
                        Text("Encumbered Credentials (\(viewModel.encumberedCreds.count))")
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
                        viewModel.newCredential = viewModel.dataController.createNewCredential()
                        viewModel.showAddCredentialSheet = true
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
            .sheet(isPresented: $viewModel.showAddCredentialSheet) {
                if let cred = viewModel.newCredential {
                    CredentialSheet(credential: cred)
                        .onDisappear {
                            if cred.name == "New Credential" {
                                viewModel.dataController.delete(cred)
                            }//: IF
                            
                        }//: ON DISAPPEAR
                }//: IF LET
                
            }//: SHEET
            
            // For showing the list of credentials of the selected type
            .sheet(item: $viewModel.selectedCat) { cat in
                CredentialSubCatListSheet(dataController: viewModel.dataController, type: cat.value)
            }//: SHEET
            
        }//: NAV VIEW
    } //: BODY
    
    //: MARK: - FUNCTIONS
   
    // MARK: - INIT
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
    
}//: STRUCT


//: MARK: - PREVIEW
#Preview {
    CredentialManagementSheet(dataController: .preview)
}


// MARK: - Custom Wrapper Struct for passing String to sheet
/// The purpose of this stuct is to allow the passing of a string binding value (selectedCat) to
/// a sheet.  SwiftUI sheets do not accept simple types like String, Int, etc.
struct CredentialCatWrapper: Identifiable {
    var id: String { value }
    let value: String
}

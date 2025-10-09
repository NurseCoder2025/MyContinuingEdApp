//
//  BasicCredentialInfoView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for the user to enter basic information (ex. name,
// credential type, number, etc.) for a given credential object

import CoreData
import SwiftUI

struct BasicCredentialInfoView: View {
    // MARK: - PROPERTIES
    
    // Needed properties:
    // - name (string)
    // - type (string)
    // - number (string)
    // - credIssuer (Issuer?)
    // - allIssuers (CoreData)
    
    // Bindings to parent view (CredentialSheet)
    @Binding var name: String
    @Binding var type: String
    @Binding var number: String
    @Binding var credIssuer: Issuer?
    
    // Property for bringing up the Issuer List sheet
    @State private var showIssuerListSheet: Bool = false
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.issuerName)]) var allIssuers: FetchedResults<Issuer>
    
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                Text("Add your license or other credential on this screen.")
            }//: SECTION
            
            Section("Basic Info") {
                // MARK: Credential name
                TextField("Credential name", text: $name)
                
                // MARK: Credential type
                Picker("Type", selection: $type) {
                    ForEach(CredentialType.pickerChoices, id: \.self) { type in
                        Text(type).tag(type.lowercased())
                    }//: LOOP
                }//: PICKER
                
                // MARK: Credential number
                TextField("Number", text: $number)
                
                // MARK: Credential issuer
                // ONLY show the picker if at least 1 issuer has been entered
                if allIssuers.isNotEmpty {
                    Picker("Issuer", selection: $credIssuer) {
                        ForEach(allIssuers) { issuer in
                            HStack {
                                Text(issuer.issuerLabel)
                                Text(issuer.country?.countryAbbrev ?? "No Country Selected")
                                    .foregroundStyle(.secondary)
                            }//: HSTACK
                            .tag(issuer)
                        }//: LOOP
                    } //: PICKER
                }//: IF
                
                Button {
                    showIssuerListSheet = true
                } label: {
                    Text(allIssuers.isEmpty ? "Add Issuer" : "Edit Issuers")
                }
                
            }//: SECTION
            
        }//: GROUP
        // MARK: - ON APPEAR
        // Using this for testing/debugging purposes
        .onAppear {
            print("type value: \(type)")
        }
        // MARK: - SHEET
        // Issuer Sheet
        .sheet(isPresented: $showIssuerListSheet) {
            IssuerListSheet()
        }
    }
}

// MARK: - PREVIEW
#Preview {
    BasicCredentialInfoView(
        name: .constant("RN License"),
        type: .constant("License"),
        number: .constant("ARY29859"),
        credIssuer: .constant(.example)
    )
}

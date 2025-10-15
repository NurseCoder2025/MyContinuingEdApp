//
//  BasicCredentialInfoView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for the user to enter basic information (ex. name,
// credential type, number, etc.) for a given credential object

// 10-13-25 update: Changed from having an optional Credential property to a non-optional

import CoreData
import SwiftUI

struct BasicCredentialInfoView: View {
    // MARK: - PROPERTIES
    @ObservedObject var credential: Credential
        
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
                TextField("Credential name", text: $credential.credentialName)
                
                // MARK: Credential type
                Picker("Type", selection: $credential.credentialCreType) {
                    ForEach(CredentialType.pickerChoices, id: \.self) { type in
                        Text(type.displaySingularName).tag(type.rawValue)
                    }//: LOOP
                }//: PICKER
                
                // MARK: Credential number
                TextField("Number", text: $credential.credentialCreNumber)
                    
                
                // MARK: Credential issuer
                Button {
                    showIssuerListSheet = true
                } label: {
                    HStack {
                        Text("Issuer: ")
                        if let selectedIssuer = credential.issuer {
                            Text(selectedIssuer.issuerIssuerName)
                                .lineLimit(1)
                        } else {
                            Text("Select")
                        }
                    }//: HSTACK
                }
                
            }//: SECTION
            
        }//: GROUP
        // MARK: - SHEET
        // Issuer Sheet
        .sheet(isPresented: $showIssuerListSheet) {
            IssuerListSheet(credential: credential)
        }//: SHEET
    }
}

// MARK: - PREVIEW
#Preview {
    BasicCredentialInfoView(credential: .example)
    
}

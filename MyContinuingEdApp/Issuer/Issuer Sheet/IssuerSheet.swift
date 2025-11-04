//
//  IssuerSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import SwiftUI

// This file is for the purpose of creating a sheet where they user can add or edit
// a credential issuer, such as a licensing board or other governing body.
//
// This view is presented from within the CredentialSheet view

// 10-13-25 update: changing issuer property to @ObservedObject non-optional in order to help
// address major bug with Issuer country and state selection properties not being saved upon change.

struct IssuerSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: ViewModel
    
    @ObservedObject var issuer: Issuer
    
    // Property for editing the issuer's name
    // Data sync issue appears in the IssuerListSheet
    // iff trying to bind entity properties directly.
    @State private var issuerNameText: String = ""
    
    // Property for showing the Country List
    @State private var showCountryListSheet: Bool = false
                                     
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Basic Information") {
                        TextField("Issuer Name", text: $issuerNameText)
                        TextField("Abbreviation:", text: $issuer.issuerAbbrev)
                        
                        // MARK: Country Selection
                        Picker("Country", selection: $issuer.country) {
                            ForEach(viewModel.allCountries) { country in
                                Text(country.countryName).tag(Optional(country))
                            }
                        }
                        .pickerStyle(.menu) // Changed from .navigationLink for better sheet appearance
                       
                        
                        // MARK: Show Country List (for editing)
                        Button {
                            showCountryListSheet = true
                        } label: {
                            Text("Edit Country List")
                        }
                        // MARK: State Selection (US ONLY)
                        if let selectedCountry = issuer.country, selectedCountry.alpha3 == "USA" {
                            Picker("State:", selection: $issuer.state) {
                                ForEach(viewModel.allStates) { state in
                                    Text("\(state.USStateName) (\(state.USStateAbbreviation))").tag(Optional(state))
                                        .accessibilityElement()
                                        .accessibilityLabel("\(state.USStateName)")
                                }
                            }
                            .pickerStyle(.menu) // Changed from .navigationLink for better sheet appearance
                        }
                    }//: SECTION
                    // MARK: Website
                    Section("Contact Information") {
                        TextField("Phone", text: $issuer.issuerPhoneNumber)
                        TextField("Email", text: $issuer.issuerEmail)
                        TextField("Website", text: $issuer.website)
                    }//: SECTION
                }//: FORM
                .navigationTitle("Credential Issuer")
                // MARK: - SHEETS
                .sheet(isPresented: $showCountryListSheet) {
                    CountryListSheet()
                }
                // MARK: SAVE Button
                HStack {
                    Spacer()
                    Button {
                        issuer.issuerName = issuerNameText
                        viewModel.dataController.save()
                        dismiss()
                    } label: {
                        Label("Save", systemImage: "internaldrive.fill")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }//: HSTACK
            }//: VSTACK
            // MARK: - TOOLBAR
            .toolbar {
                // Dismiss button
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {dismiss()}){
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
                
                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        issuer.issuerName = issuerNameText
                        viewModel.dataController.save()
                        dismiss()
                    }) {
                        Text("Save")
                    }
                }//: TOOLBAR ITEM
                            
            }//: TOOLBAR
            // MARK: - ON APPEAR
            .onAppear {
                issuerNameText = issuer.issuerIssuerName
            }//: ON APPEAR
        }//: NAV VIEW
    }//: BODY
    
    // MARK: - INIT
    init(dataController: DataController, issuer: Issuer) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.issuer = issuer
    }//: INIT
    
    
}//: ISSUER SHEET STRUCT


// MARK: - PREVIEW
#Preview {
   
}

//
//  IssuerSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import CoreData
import SwiftUI

// This file is for the purpose of creating a sheet where they user can add or edit
// a credential issuer, such as a licensing board or other governing body.

struct IssuerSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    let issuer: Issuer?
    
    // Properties for edting the values of an Issuer object
    @State private var name: String = ""
    @State private var issuerAbbreviation: String = ""
    @State private var country: Country?
    @State private var state: USState?
    @State private var webSite: String = ""
    @State private var issuerPhone: String = ""
    @State private var issuerEmailAddress: String = ""

    // Property for showing the Country List
    @State private var showCountryListSheet: Bool = false
    
    // MARK: - Computed Properties
        
    
    // MARK: - CORE DATA Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]) var allCountries: FetchedResults<Country>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.stateName)]) var allStates: FetchedResults<USState>
                                     
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Basic Information") {
                        TextField("Issuer Name", text: $name)
                        TextField("Abbreviation:", text: $issuerAbbreviation)
                        // MARK: Country Selection
                        Picker("Country", selection: $country) {
                            ForEach(allCountries) {country in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(country.countryAbbrev)
                                        .bold()
                                        .foregroundStyle(.primary)
                                    Text(country.countryName)
                                        .foregroundStyle(.secondary)
                                }//: VSTACK
                                .tag(country)
                            }//: LOOP
                        }//: COUNTRY PICKER
                        .pickerStyle(.navigationLink)
                        
                        // MARK: Show Country List (for editing)
                        Button {
                            showCountryListSheet = true
                        } label: {
                            Text("Edit Country List")
                        }
                        
                        // MARK: State Selection (US ONLY)
                        if let chosenCountry = issuer?.country {
                            if chosenCountry.name == "United States of America" {
                                Picker("State:", selection: $state) {
                                    ForEach(allStates) {state in
                                        StatePickerRowView(state: state).tag(state)
                                    }//: LOOP
                                }//: STATE PICKER
                                .pickerStyle(.navigationLink)
                            } //: if country is the US
                        //: If a country has been chosen for the issuer
                        } else {
                            // If creating a new country and no object has been saved yet
                            if let pickedCountry = country {
                                if pickedCountry.countryAbbrev == "USA" {
                                    Picker("State:", selection: $state) {
                                        ForEach(allStates) {state in
                                            StatePickerRowView(state: state).tag(state)
                                        }//: LOOP
                                    }//: STATE PICKER
                                    .pickerStyle(.navigationLink)
                                } // If the selected country in the picker is the US
                            } //: IF-LET
                        }//: ELSE (no country object yet)
                        
                    }//: SECTION
                    
                    // MARK: Website
                    Section("Contact Information") {
                        TextField("Phone", text: $issuerPhone)
                        TextField("Email", text: $issuerEmailAddress)
                        TextField("Website", text: $webSite)
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
                            mapAndSave()
                            dismiss()
                        } label: {
                            Label("Save & Dismiss", systemImage: "internaldrive.fill")
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }//: HSTACK
                
            }//: VSTACK
            // MARK: - TOOLBAR
            .toolbar {
                // Dismiss button
                Button(action: {dismiss()}){
                    DismissButtonLabel()
                }.applyDismissStyle()
            }
            
            // MARK: - ON APPEAR
            .onAppear {
                // If editing an existing Issuer object, assign property values to each of the
                // view's @State properties
                if let editingIssuer = issuer {
                    name = editingIssuer.name
                    issuerAbbreviation = editingIssuer.issuerAbbrev
                    country = editingIssuer.country
                    state = editingIssuer.state
                    webSite = editingIssuer.website
                    issuerPhone = editingIssuer.issuerPhoneNumber
                    issuerEmailAddress = editingIssuer.issuerEmail
                } else {
                    // Setting the country to the U.S. as default value if creating
                    // a new Issuer object
                    if country == nil {
                        country = allCountries.first(where: { $0.name == "United States of America" })
                    }
                }
            }//: ON APPEAR
            
            
        }//: NAV VIEW
    }//: BODY
    
    
    // MARK: - Custom functions
    /// Saves the current state of what is in the Issuer sheet fields (except for country as that has already been
    /// mapped by the showCountrySheetList.
    func mapAndSave() {
        if let passedInIssuer = issuer {
            passedInIssuer.name = name
            passedInIssuer.issuerAbbrev = issuerAbbreviation
            passedInIssuer.country = country
            passedInIssuer.state = state
            passedInIssuer.website = webSite
            passedInIssuer.email = issuerEmailAddress
            passedInIssuer.phoneNumber = issuerPhone
        } else {
            let viewContext = dataController.container.viewContext
            let newIssuer = Issuer(context: viewContext)
            
            // mapping fields to new object
            newIssuer.name = name
            newIssuer.issuerAbbrev = issuerAbbreviation
            newIssuer.country = country
            newIssuer.state = state
            newIssuer.website = webSite
            newIssuer.email = issuerEmailAddress
            newIssuer.phoneNumber = issuerPhone
        }
        
        dataController.save()
    }
    
    
    // MARK: - Custom INIT
    
    
}//: ISSUER SHEET STRUCT


// MARK: - PREVIEW
#Preview {
    IssuerSheet(issuer: .example)
}

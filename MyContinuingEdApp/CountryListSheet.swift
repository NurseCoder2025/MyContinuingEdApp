//
//  CountrySheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/3/25.
//

import CoreData
import SwiftUI

// Sheet for displaying all country objects currently in persistent storage.  The DataController
// will preload default Country objects on first install/use of the app, but then the user can
// edit the list at will.  View utilizes alerts for edting and creating Country objects since
// each country object only needs two properties.
//
// This view will ONLY be called by the IssuerSheet view as that is the only place where the user
// would need to edit the list of Country objects.

struct CountryListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Property for storing the currently selected activity
    @State private var selectedCountry: Country?
    
    // Properties for editing or adding a new country
    @State private var countryToEdit: Country?
    @State private var countryName: String  = ""
    @State private var countryAbbreviation: String = ""
    
    // Alert properties
    @State private var showEditAlert: Bool = false
    @State private var deleteCountrAlert: Bool = false
    @State private var addCountryAlert: Bool = false
    
    // Search property
    @State private var searchText: String = ""
    
    // MARK: - CORE DATA Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCountries: FetchedResults<Country>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            List(selection: $selectedCountry) {
                ForEach(allCountries.filter { country in
                    searchText.isEmpty || country.countryName.localizedCaseInsensitiveContains(searchText) || country.countryAbbrev.localizedCaseInsensitiveContains(searchText)
                }) { country in
                    HStack {
                        Text(country.countryAbbrev)
                            .bold()
                        Text("|")
                        Text(country.countryName)
                            .foregroundStyle(.secondary)
                    }//: HSTACK
                    
                    // MARK: SWIPE ACTIONS
                    .swipeActions(edge: .trailing) {
                        // Delete button
                        Button(role: .destructive) {
                            deleteCountry(country)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        // Edit button
                        Button {
                            countryToEdit = country
                            showEditAlert = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                    }
                }//: LOOP
                
                
            }//: LIST
            .navigationTitle("Countries")
            // MARK: - Toolbar
            .toolbar {
                // Add Country button
                Button {
                    addCountryAlert = true
                } label: {
                    Label("Add Country", systemImage: "plus")
                }
                
                // Dismiss button
                Button(action: {dismiss()}){
                    DismissButtonLabel()
                }.applyDismissStyle()
                
            }
            // MARK: - ALERTS
            // MARK: Edit Country ALERT
            .alert("Edit Country", isPresented: $showEditAlert) {
                TextField("Name:", text: $countryName)
                TextField("Abbreviation:", text: $countryAbbreviation)
                Button("Save") { if let country = countryToEdit { confirmCountryEdit(country) } }
                Button("Cancel", role: .cancel) {}
                
            } message: {
                Text("Update the selected country's information by typing in either a new name or abbreviation in the textfields below.")
            }
            // MARK: Add Country ALERT
            .alert("Add Country", isPresented: $addCountryAlert) {
                TextField("Name:", text: $countryName)
                TextField("Abbreviation:", text: $countryAbbreviation)
                Button("Save") { createNewCountry() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Add a new country by filling in both fields below.")
            }
            .searchable(text: $searchText, prompt: "Search countries")
            
        }//: NAV VIEW
    }
    
    // MARK: - Sheet Methods
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = allCountries[offset]
            dataController.delete(item)
        }
    }//: DELETE function
    
    ///  Updates the seleted Country object's name and abbreviation properties to whatever text the user has entered into the text fields.
    /// - Parameter country: Country object passed in from the List that has been swiped
    func confirmCountryEdit(_ country: Country) {
        let trimmedName = countryName.trimmingCharacters(in: .whitespaces)
        let trimmedAbbrev = countryAbbreviation.trimmingCharacters(in: .whitespaces)
        
        // If the user typed a value into the countryName field to edit it
        if trimmedName.count > 0 {
            country.name = countryName
        }
        
        // If the user typed a value into the countryAbbreviation field to edit (add) it
        if trimmedAbbrev.count > 0 {
            country.userAbbrev = countryAbbreviation
        }
        
        dataController.save()
    }
    
    func createNewCountry() {
        let newCountry = Country(context: dataController.container.viewContext)
        newCountry.name = countryName
        newCountry.userAbbrev = countryAbbreviation
        
        dataController.save()
    }
    
    func deleteCountry(_ country: Country) {
        dataController.delete(country)
    }
}

// MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    let viewContext = controller.container.viewContext
    
    CountryListSheet()
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(controller)
}

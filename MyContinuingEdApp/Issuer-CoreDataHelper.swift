//
//  Issuer-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import Foundation

// The purpose of this file is to include extensions to the Issuer Core Data entity for making it easier working with properties within
// SwiftUI due to Core Data optionals.

extension Issuer {
    // Computed properties to handle Core Data optionals for Strings
    
    var name: String {
        get {issuerName ?? ""}
        set {issuerName = newValue}
    }
    
    var issuerAbbrev: String {
        get {abbreviation ?? ""}
        set {abbreviation = newValue}
    }
    
    var website: String {
        get {issuerWebSite ?? ""}
        set {issuerWebSite = newValue}
    }
    
    var issuerPhoneNumber: String {
        get {phoneNumber ?? ""}
        set {phoneNumber = newValue}
    }
    
    var issuerEmail: String {
        get {email ?? ""}
        set {email = newValue}
    }
    
    
} //: EXTENSION


// Creating an example for preview purposes
extension Issuer {
    static var example: Issuer {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        // Fetching country and state for example purposes
        let countryFetch = Country.fetchRequest()
        countryFetch.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let fetchedCountries = (try? context.fetch(countryFetch)) ?? []
        
        let stateFetch = USState.fetchRequest()
        let fetchedStates = (try? context.fetch(stateFetch)) ?? []
        
        // Assigning a sample item to placeholder variables
        let sampleCountry = fetchedCountries[0]
        let sampleState = fetchedStates[0]
        
        
        let exampleIssuer = Issuer(context: context)
        exampleIssuer.name = "Ohio Board of Nursing"
        exampleIssuer.abbreviation = "OBN"
        exampleIssuer.website = "https://nursing.ohio.gov/verification.htm"
        exampleIssuer.country = sampleCountry
        exampleIssuer.state = sampleState
        exampleIssuer.email = "licensing.board@board.state.us"
        exampleIssuer.phoneNumber = "(303) 798 - 2144"
        
        return exampleIssuer
    }
    
} //: EXTENSION


// Creating a computed property that returns either the abbreviation or
// name of the issuer, depending on what has been entered
extension Issuer {
    var issuerLabel: String {
        if issuerAbbrev == "" {
            return name
        } else {
            return issuerAbbrev
        }
    }
}

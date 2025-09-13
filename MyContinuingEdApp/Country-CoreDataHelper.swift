//
//  Country-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/3/25.
//

import Foundation

extension Country {
    
    var countryID: UUID {
        return id ?? UUID()
    }
    
    var countryName: String {
        get {name ?? ""}
        set {name = newValue}
    }
    
    var countryAlpha2: String {
        get {alpha2 ?? ""}
        set {alpha2 = newValue}
    }
    
    var countryAlpha3: String {
        get {alpha3 ?? ""}
        set {alpha3 = newValue}
    }
    
    var countryUserAbbrev: String {
        get {userAbbrev ?? ""}
        set {userAbbrev = newValue}
    }
}


// Creating an example Country for preview purposes
extension Country {
    
    static var example: Country {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let exampleCountry = Country(context: context)
        exampleCountry.name = CountryJSON.example.name
        exampleCountry.alpha2 = CountryJSON.example.alpha2
        exampleCountry.alpha3 = CountryJSON.example.alpha3
        
        return exampleCountry
    }
}

// Adding a computed property that will return either the alpha3 abbreviation for a country,
// the user's entered abbreviation, OR "unspecified" if neither condition applies
extension Country {
    
    var countryAbbrev: String {
        var returnedAbbrev: String = ""
        
        // Look for the alpha3 value first and assign that to returnedAbbrev
        if let setAlpha3 = alpha3 {
            returnedAbbrev = setAlpha3
        // If no alpha3, then look for a user-entered abbreviation and assign that to returnedAbbrev
        } else if let userEnteredAbbrev = userAbbrev {
            returnedAbbrev = userEnteredAbbrev
        // If neither applies, return a general "unspecified" string value
        } else {
            returnedAbbrev = "Unspecified"
        }
        
       return returnedAbbrev
    }
    
}

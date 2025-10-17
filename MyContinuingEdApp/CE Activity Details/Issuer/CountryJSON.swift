//
//  Country.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import Foundation

struct CountryJSON: Decodable {
    var name: String
    var alpha2: String
    var alpha3: String
    var sortOrder: Int16
   
// customizing how countries are to be sorted
    static func <(lhs: CountryJSON, rhs: CountryJSON) -> Bool {
        let leftSide = lhs.name.localizedLowercase
        let rightSide = rhs.name.localizedLowercase
        
        if leftSide == rightSide {
            return lhs.alpha3 < rhs.alpha3
        } else {
            return leftSide < rightSide
        }
    }
    
    // Decoding all countries into a static property
    static let allDefaultCountries:[CountryJSON] = Bundle.main.decode("Country List.json")
    
    // Setting the U.S. as the default country
    static let defaultCountry: CountryJSON = allDefaultCountries[132]
    
    // Setting the first country in the list as an example for development purposes
    static let example: CountryJSON = allDefaultCountries[0]
 
}

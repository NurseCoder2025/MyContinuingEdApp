//
//  CeDesignationJSON.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/25/25.
//

import Foundation

struct CeDesignationJSON: Decodable {
    let designationAbbreviation: String
    let designationName: String
    let designationAKA: String
    
    // Adding all default designation objects into a static property for testing purposes
    static let defaultDesignations: [CeDesignationJSON] = Bundle.main.decode("Default CE Designations.json")
}

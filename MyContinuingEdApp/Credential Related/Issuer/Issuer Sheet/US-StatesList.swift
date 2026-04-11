//
//  US-StatesList.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import Foundation


struct USStateJSON: Decodable {
    var stateName: String
    var abbreviation: String
    
    // Decoding all states and abbreviations from internal JSON file
    static let allStates: [USStateJSON] = Bundle.main.decode("USStatesList.json")
    
    // Example state
    static let example = allStates[0]
        
}

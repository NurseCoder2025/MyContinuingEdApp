//
//  InactiveReasons-Defaults.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import Foundation

struct InactiveReasons: Decodable, Identifiable {
    var id: String {reasonName}
    var reasonName: String
}

// Decoding internal JSON file and creating sample item
extension InactiveReasons {
    static var defaultReasons: [InactiveReasons] {
        Bundle.main.decode("Inactive Reasons.json")
    }
    
    static let example = defaultReasons[0]
}

//
//  Awards.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/24/25.
//

import Foundation

struct Award: Decodable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var description: String
    var notificationText: String
    var color: String
    var criterion: String
    var value: Int
    var image: String
    
    static let allAwards: [Award] = Bundle.main.decode("Awards.json")
    static let example: Award = allAwards[0]
    
}

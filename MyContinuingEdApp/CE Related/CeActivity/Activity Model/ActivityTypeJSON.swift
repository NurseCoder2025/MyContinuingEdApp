//
//  ActivityTypeJSON.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/27/25.
//

import Foundation

struct ActivityTypeJSON: Decodable, Identifiable {
    var id: String {typeName}
    var typeName: String
    
    // Creating a static property to hold all decoded activity type default values for testing purposes
    static let allActivityTypes: [ActivityTypeJSON] = Bundle.main.decode("Activity Types.json")
}

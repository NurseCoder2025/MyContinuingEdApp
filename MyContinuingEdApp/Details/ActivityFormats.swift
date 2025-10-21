//
//  ActivityFormatsJSON.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/27/25.
//

import Foundation

struct ActivityFormat: Decodable, Identifiable {
    var id: String {formatName}
    var formatName: String
    var image: String
    
    static let allFormats: [ActivityFormat] = Bundle.main.decode("Activity Formats.json")
    static let example: ActivityFormat = allFormats[0]
}

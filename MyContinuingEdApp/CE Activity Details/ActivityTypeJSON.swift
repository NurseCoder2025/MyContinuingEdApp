//
//  ActivityTypeJSON.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/27/25.
//

struct ActivityTypeJSON: Decodable, Identifiable {
    var id: String {typeName}
    var typeName: String
}

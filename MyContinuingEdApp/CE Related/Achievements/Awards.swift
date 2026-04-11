//
//  Awards.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/24/25.
//

import Foundation

/// The Award struct represents possible achievements that the user can earn in regards to
/// the use of the app.
///
/// - Properties:
///     - id: the name of the award (as a String)
///     - name: String representing the name of the award
///     - "description": String representing the requirements for earning the award
///     - notificationText: String for what text to display in the body of the notification
///     generated whenever the award is achieved
///     - color: String value representing a possible Color value for when the award is earned
///     - criterion: single word String that describes a general rule for determining if an award
///     is earned
///     - value: Int indicating the number of items that must meet the criteria set for the
///     criterion in order for the award to be earned
///     - image: String representing a SF symbol icon for the award
///
/// - Static properties:  allAwards (decodes everything in the Awards.json file) and example (first
/// item from the allAwards array).
///
/// - Important: Objects of this type are NOT CoreData entities.
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
    
}//: Award

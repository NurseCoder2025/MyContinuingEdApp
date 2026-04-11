//
//  Enums-DisciplinaryActionItem.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import Foundation


// Purpose: To provide enums that can store a set number of values for
// DisciplinaryActionItem properties that don't need user editing

/// The main types of disicpline that can be effected by a credential governing body. These case values
///  will serve as picker choices that will populate the actionType property in the DisciplinaryActionItem
///  object.
///
///  Type values include: warning, reprimand, suspension, & revocation
enum DisciplineType: String, CaseIterable {
    case warning, reprimand, suspension, revocation
}


/// The values for this enum are intended to be placed in the actionsTaken property for each
///  DisciplinaryActionItem entity object.  They will be added in a text box like the tags search field in
///  the CeActivity view.
///  -  Type Values:
///     - fines
///     - probation
///     - altProgram (alternative program - meaning a custom training program meant to rehab the
///     credential holder based on what got them into disciplinary action)
///     - continuingEd (extra continuing education courses)
///     - community (community service hours requirement)
///     - credSuspension
///     - credLoss
///
///  Enum needs to conform to Codable because these values are used as a Transformable data
///  type in CoreData, so they must be saved as JSON objects.
enum DisciplineAction: String, CaseIterable, Codable {
    case fines = "fine(s)"
    case probation
    case altProgram = "alternative program"
    case continuingEd = "continuing education"
    case community = "community service"
    case credSuspsension = "credential suspended"
    case credLoss = "credential lost"
}

//
//  USState-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/4/25.
//

import Foundation

extension USState {
    
    var USStateAbbreviation: String {
        get {abbreviation ?? ""}
        set {abbreviation = newValue}
    }
    
    var USStateName: String {
        get {stateName ?? ""}
        set {stateName = newValue}
    }
}

// Creating an example U.S. state
extension USState {
    var example: USState {
        let controller = DataController(inMemory: true)
        let container = controller.container
        let viewContext = container.viewContext
        
        let exampleState = USState(context: viewContext)
        exampleState.stateName = "Ohio"
        exampleState.abbreviation = "OH"
        
        return exampleState
    }
}

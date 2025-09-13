//
//  CeType-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/22/25.
//

import Foundation

extension CeDesignation {
    
    var ceDesignationName: String {
        get {designationName ?? ""}
        set {designationName = newValue}
    }
    
    var ceDesignationAbbrev: String {
        get {designationAbbreviation ?? ""}
        set {designationAbbreviation = newValue}
    }
    
    var ceDesignationAKA: String {
        get {designationAKA ?? ""}
        set {designationAKA = newValue}
    }
    
    var ceDesignationID: UUID {
        return designationID ?? UUID()
    }
    
    // Setting a sample CE Type for previewing purposes
    static var example: CeDesignation {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let type = CeDesignation(context: context)
        type.designationName = "Nursing Continuing Education"
        type.designationAbbreviation = "Nursing CE"
        type.designationAKA = "Continuing Nursing Education (CNE)"
        
        return type
    }
}


// extension to make CeDesignation conform to Decodable




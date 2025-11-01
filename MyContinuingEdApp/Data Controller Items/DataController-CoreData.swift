//
//  DataController-CoreData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/1/25.
//

import CoreData
import Foundation


extension DataController {
    
    /// This function returns the UUID property for all Core Data entities in this app as a String value
    /// for testing purposes.
    /// - Parameter object: Core Data entity you wish to get the UUID for
    /// - Returns: UUID value for the object as a String
    func getUUIDString(for object: NSManagedObject) -> String? {
        let possibleKeys: [String] = [
            "reflectionID",
            "typeID",
            "activityID",
            "designationID",
            "credentialID",
            "disciplineID",
            "issuerID",
            "periodID",
            "specialCatID",
            "tagID",
            "stateID",
            "countryID"
        ]
        
        for key in possibleKeys {
            if object.entity.propertiesByName.keys.contains(key), let id = object.value(forKey: key) as? UUID {
                return id.uuidString
            }
        }//: LOOP
        
        return nil
    }//: getUUIDString(object)
    
    
}//: DATA CONTROLLER

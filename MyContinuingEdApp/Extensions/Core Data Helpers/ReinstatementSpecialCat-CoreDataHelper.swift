//
//  ReinstatementSpecialCat-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import Foundation

// MARK: - COMPARABLE Conformance
extension ReinstatementSpecialCat: Comparable {
    
    /// Method for making the ReinstatementSpecialCat object (CoreData object) conform to Comparable.  This way
    /// multiple ReinstatementSpecialCat objects can be sorted wherever needed in the app.
    /// - Parameters:
    ///   - lhs: ReinstatementSpecialCat object to compare
    ///   - rhs: ReinstatementSpecialCat object to compare
    /// - Returns: true if the lhs object comes before the rhs; false if not
    ///
    /// Becuase the ReinstatementSpecialCat object only has two internal properties, rscID and cesRequired, the object
    /// will first be compared by whatever SpecialCategory object is assigned to the specialCat property of each (assuming
    /// those are not nil), and if they are the same, then the objects will be compared according to the number of CEs required.
    /// If a SpecialCategory object has not been assigned to both or to either one, then the comparison will only be based on
    /// the number of CEs required (via the cesRequired property).
    ///
    /// The reasoning for this cokmparison logic is because the ReinstatementSpecialCat is really a holder object that allows
    /// a SpecialCategory object required for credential reinstatement to be associated with a specific number of CEs. Under
    /// the ReinstatementInfo object, there can be many ReinstatementSpecialCat objects, each holding the SpecialCategory
    /// (as a relationship property) along with an internal property of cesRequired that holds the number of CEs for that
    /// category which are required by a credential governing board or body.
    public static func <(lhs: ReinstatementSpecialCat, rhs: ReinstatementSpecialCat) -> Bool {
        if let lAssignedSpecCat = lhs.specialCat, let rAssignedSpecCat = rhs.specialCat {
            let leftName = lAssignedSpecCat.specialName
            let rightName = rAssignedSpecCat.specialName
            
            if leftName == rightName {
                return lhs.cesRequired < rhs.cesRequired
            } else {
                return leftName < rightName
            }
        } else {
            return lhs.cesRequired < rhs.cesRequired
        }
    }//: <
}//: EXTENSION

// MARK: - EXAMPLE
extension ReinstatementSpecialCat {
    static var example: ReinstatementSpecialCat {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let sampleSpecialCat = SpecialCategory(context: context)
        sampleSpecialCat.specialCatID = UUID()
        sampleSpecialCat.specialName = "Special Cat"
        sampleSpecialCat.abbreviation = "SC"
        sampleSpecialCat.catDescription = "This is a special cat"
        sampleSpecialCat.requiredHours = 2.5
        
        let sampleRCS = ReinstatementSpecialCat(context: context)
        sampleRCS.rscID = UUID()
        sampleRCS.cesRequired = 25.0
        sampleRCS.specialCat = sampleSpecialCat
        
        controller.save()
        return sampleRCS
    }//: example
    
}//: EXTENSION

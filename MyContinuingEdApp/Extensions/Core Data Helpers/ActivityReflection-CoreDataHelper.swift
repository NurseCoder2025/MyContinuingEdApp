//
//  ActivityReflection-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation

// MARK: - UI HELPERS
extension ActivityReflection {
   
    var reflectionDateAdded: Date {
        get { dateAdded ?? Date.now }
        set { dateAdded = newValue }
    }
    
    var reflectionLastModified: Date  {
        lastModified ?? Date.now
    }
    
    var reflectionSurprises: String {
        get { surprises ?? "" }
        set { surprises = newValue }
    }
    
    var reflectionReflectionID: UUID {
        reflectionID ?? UUID()
    }
    
    var afGeneralReflection: String {
        get {
            generalReflection ?? ""
        }
        set {
            generalReflection = newValue
        }
    }//: afGeneralReflection
    
}//: EXTENSION

// MARK: - COMPUTED PROPERTIES
extension ActivityReflection {

    
}//: EXTENSION

// MARK: - RELATIONSHIPS
extension ActivityReflection {
    
    /// Computed CoreData helper property that returns all ReflectionResponse objects connected to
    /// a specific ActivityReflection object in an array.
    var reflectionResponses: [ReflectionResponse] {
        responses?.allObjects as? [ReflectionResponse] ?? []
    }//: reflectionResponses
    
}//: EXTENSION

// MARK: - METHODS
extension ActivityReflection {
    // TODO: Add 1 method to ActivityReflection extension
    
    // Add method that updates the surpriseEntered property when the user
    // has entered a valid surprise
    
}//: EXTENSION

// MARK: - Sample Reflection
extension ActivityReflection {
    
    static var example: ActivityReflection {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let sampleReflection = ActivityReflection(context: context)
        sampleReflection.reflectionID = UUID()
        sampleReflection.generalReflection = """
        Wow, this CE course was so helpful and interesting.  Hope to take more
        like this one!
        """
        
        sampleReflection.reflectionSurprises = """
        No real surprises here today...
        """
        
        return sampleReflection
    }
    
    
}

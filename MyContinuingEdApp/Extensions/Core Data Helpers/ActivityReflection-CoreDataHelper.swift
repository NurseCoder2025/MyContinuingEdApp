//
//  ActivityReflection-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import Foundation


extension ActivityReflection {
    // MARK: - UI HELPERS
    
    var reflectionDateAdded: Date {
        get { dateAdded ?? Date.now }
        set { dateAdded = newValue }
    }
    
    var reflectionLastModified: Date  {
        lastModified ?? Date.now
    }
    
    var reflectionThreeMainPoints: String {
        get { threeMainPoints ?? "" }
        set { threeMainPoints = newValue }
    }
    
    var reflectionSurprises: String {
        get { surprises ?? "" }
        set { surprises = newValue }
    }
    
    var reflectionLearnMoreAbout: String {
        get {learnMoreAbout ?? ""}
        set {learnMoreAbout = newValue}
    }
    
    var reflectionGeneralReflection: String {
        get {generalReflection ?? ""}
        set {generalReflection = newValue}
    }
    
    var reflectionReflectionID: UUID {
        reflectionID ?? UUID()
    }
    
}//: EXTENSION

// MARK: - COMPUTED PROPERTIES
extension ActivityReflection {
    
    // Adding another computed property that returns TRUE if the user
    // typed in reflections in at least two of the four fields (generalReflection &
    // threeMainPoints)
    var completedReflection: Bool {
        let actualGenReflection = reflectionGeneralReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let actualThreeMainPoints = reflectionThreeMainPoints.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if actualGenReflection.count > 0 && actualThreeMainPoints.count > 0 {
            completedYN = true
            return true
        } else {
            completedYN = false
            return false
        }
    }//: completedReflection

    /// The enteredASurprise computed property is intended for use in fetch requests
    /// for awards related to the user journaling about what things surprised them
    /// during a given CE activity
    var enteredASurprise: Bool {
        let actualSurpriseText = reflectionSurprises.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if actualSurpriseText.count > 0 {
            surpriseEntered = true
            return true
        } else {
            return false
        }
    }//: enteredASurprise
    
}//: EXTENSION

// MARK: - RELATIONSHIPS
extension ActivityReflection {
    
    /// Computed CoreData helper property that returns all ReflectionResponse objects connected to
    /// a specific ActivityReflection object in an array.
    var reflectionResponses: [ReflectionResponse] {
        responses?.allObjects as? [ReflectionResponse] ?? []
    }//: reflectionResponses
    
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
        sampleReflection.reflectionThreeMainPoints = """
        1. Study hard
        2. Get lots of sleep
        3. Eat healthy
        """
        sampleReflection.reflectionSurprises = """
        No real surprises here today...
        """
        
        return sampleReflection
    }
    
    
}

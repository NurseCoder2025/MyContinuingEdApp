//
//  ReflectionPrompt-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

import Foundation

extension ReflectionPrompt {
    
    // MARK: - UI HELPERS
    
    /// CoreData computed property helper that gets and sets values for the
    /// ReflectionPrompt question property. If the property is nil, then "No
    /// Question" is returned.
    var promptQuestion: String {
        get {
            question ?? "No Question"
        }
        set {
            question = newValue
        }
        
    }//: promptQuestion
    
    
}//: EXTENSION

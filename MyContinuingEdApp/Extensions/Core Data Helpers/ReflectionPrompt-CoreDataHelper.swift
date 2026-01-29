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
    
    // MARK: - EXAMPLES
    
    static var shortExample: ReflectionPrompt {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let samplePrompt = ReflectionPrompt(context: context)
        samplePrompt.id = UUID()
        samplePrompt.customYN = false
        samplePrompt.promptQuestion = "The idea that most surprised me was..."
        
        return samplePrompt
    }//: example
    
    static var longExample: ReflectionPrompt {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let samplePrompt = ReflectionPrompt(context: context)
        samplePrompt.id = UUID()
        samplePrompt.customYN = false
        samplePrompt.promptQuestion = "Six months from now I'll be a better professional than I was before participating in this activity because..."
        
        return samplePrompt
    }//: longExample
    
    
}//: EXTENSION

// MARK: - PROTOCOL CONFROMANCE
extension ReflectionPrompt: SyncIdentifiable {
    var syncID: String { promptQuestion }
}//: EXTENSION

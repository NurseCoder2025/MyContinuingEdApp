//
//  PromptCategories-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/25/26.
//

import CoreData
import Foundation


extension PromptCategory {
    
    // MARK: - UI Helpers
    
    var catName: String {
        get {
            categoryName ?? "N/A"
        }
        set {
            categoryName = newValue
        }
    }//: catName
    
    // MARK: - RELATIONSHIPS
    
    var assignedPrompts: [ReflectionPrompt] {
        questions?.allObjects as? [ReflectionPrompt] ?? []
    }//: assignedPrompts
    
    var assignedFavoritePrompts: [ReflectionPrompt] {
        let allPrompts = assignedPrompts
        let favoritePrompts = allPrompts.filter({$0.favoriteYN == true})
        return favoritePrompts
    }//: assignedFavoritePrompts
    
    var assignedCustomPrompts: [ReflectionPrompt] {
        let allPrompts = assignedPrompts
        let customPrompts = allPrompts.filter({$0.customYN == true})
        return customPrompts
    }//: assignedCustomPrompts
    
    var hasCustomPrompts: Bool {
        assignedCustomPrompts.count > 0
    }//: hasCustomPrompts
    
    var hasFavoritePrompts: Bool {
        assignedFavoritePrompts.count > 0
    }//: hasFavoritePrompts
    
}//: EXTENSION

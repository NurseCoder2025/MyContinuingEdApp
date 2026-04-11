//
//  PromptCategoryJSON.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/25/26.
//

import Foundation


struct PromptCategoryJSON: Codable, Identifiable {
    // MARK: - PROPERTIES
    let categoryName: String
    
    // MARK: - COMPUTED PROPERTIES
    var id: String { categoryName }
    
    var capitalizedName: String {categoryName.capitalized}//: capitalizedName
    
    // MARK: - DECODED VALUES
    
    static let standardPrompts: [PromptCategoryJSON] = Bundle.main.decode("Prompt Categories.json")
    
}//: PromptCategoryJSON

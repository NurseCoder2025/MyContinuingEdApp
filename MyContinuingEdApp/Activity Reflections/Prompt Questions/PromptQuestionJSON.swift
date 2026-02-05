//
//  PromptQuestionsJSON.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

import Foundation


/// Struct for creating a data type for the pre-created actiivty reflection prompts
/// that are saved in the "Reflection Prompts.json" file within the app bundle.
///
/// - Important: This struct is only intended to be an intermediary between the raw
/// JSON data and the CoreData entity ReflectionPrompt (which has the same properties).
/// Use the static officialPrompts property to decode the file and then use those values for
/// creating the actual ReflectionPrompt objects.
struct PromptQuestionJSON: Decodable, Identifiable, Hashable, SyncIdentifiable {
    // MARK: - PROPERTIES
    let question: String
    let customYN: Bool
    
    // Conforming to Identifable by using the question String as
    // a unique identifier
    var id: String { question }
    
    // SyncID conformance so objects created by this struct can be
    // compared with their CoreData counterpart (ReflectionPrompt)
    
    /// Computed property for PromptQuestionJSON which returns the question
    /// String property value.  This is required for SyncIdentifiable conformance.
    ///
    /// - Important: Getter ONLY - do not try to set a value with this!
    var syncID: String {question}
    
    // MARK: - STATIC Properites
    static let officialPrompts: [PromptQuestionJSON] = Bundle.main.decode("Reflection Prompts.json")
    
}//: PromptQuestionJSON

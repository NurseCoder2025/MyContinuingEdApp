//
//  ReflectionPrompt-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/27/26.
//

import Foundation

extension ReflectionResponse {
    
    // MARK: - UI Helpers
    
    /// Computed CoreData helper property that gets and sets values for the answer property for ReflectionResponse.
    /// If the property is nil, the String "Not answered yet" will be returned.
    var responseAnswer: String {
        get {
            answer ?? "Not answered yet"
        }
        set {
            answer = newValue
        }
    }//: promptAnswer
    
    var responseModified: Date {
        modifiedOn ?? Date.now
    }//: responseModified
    
     // MARK: - METHODS
    
    /// CoreData helper method for ReflectionResponse that determines if the user has likely entered a complete
    /// answer for a given prompt and updates the corresponding property accordingly.
    ///
    /// - Note: There must be at least 50 characters in the answer String field (excluding white spaces and
    /// new lines) in order for the completeAnswerYN property to marked as true.
    func markResponseAsComplete() {
        let answerWordCount = responseAnswer.trimmingCharacters(in: .whitespacesAndNewlines).count
        if answerWordCount >= 50 {
            self.completeAnswerYN = true
        } else {
            self.completeAnswerYN = false
        }
    }//: markResponseAsComplete
    
}//: EXTENSION

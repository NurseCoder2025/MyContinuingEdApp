//
//  ReflectionPrompt-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/27/26.
//

import AVFoundation
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
    
    /// Async CoreData helper method for ReflectionResponse that determines if the user has likely entered a complete
    /// answer for a given prompt and updates the corresponding property accordingly.
    ///
    /// - Note: There must be at least 15 characters in the answer String field (excluding white spaces and
    /// new lines) or at least 10 seconds of recorded audio in order for the completeAnswerYN property to marked as true.
    func markResponseAsComplete() async {
        // If the user has just updated the response, re-run the
        // method logic to ensure it is still a complete response
        let calendar = Calendar.current
        let todaysDate = calendar.startOfDay(for: Date.now)
        let modDate = calendar.startOfDay(for: self.responseModified)
        
        guard self.completeAnswerYN == false || modDate == todaysDate else {return}
        
        if let enteredText = self.answer {
            let trimmedText = enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText.count >= 15 {
                self.completeAnswerYN = true
            } else {
                self.completeAnswerYN = false
            }
        } else if self.hasAudioReflection, let transcribedText = self.answer {
            let trimmedAnswer = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedAnswer.count >= 75 {
                self.completeAnswerYN = true
            } else {
                self.completeAnswerYN = false
            }
        } else {
            self.completeAnswerYN = false
        }//: IF ELSE
    }//: markResponseAsComplete
    
    // MARK: - RELATIONSHIPS
    
    /// ReflectionResponse CoreData helper method that retrieves the question text from the ReflectionPrompt object
    /// assigned to the question relationship property for each ReflectionResponse object.
    /// - Returns: The question String value from the ReflectionPrompt object, or "No question assigned yet" if either
    /// no question has been assigned yet or the question property is nil
    func getAssignedPrompt() -> String {
        if let assignedPrompt = self.question, let questionText = assignedPrompt.question {
            return questionText
        } else {
            return "No question assigned yet..."
        }
    }//: getAssignedPrompt()
    
    // MARK: - EXAMPLE
    
    static var example: ReflectionResponse {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let sampleQuestion = ReflectionPrompt(context: context)
        sampleQuestion.id = UUID()
        sampleQuestion.question = "I really wish the speaker(s) would have..."
        
        let exampleResponse = ReflectionResponse(context: context)
        exampleResponse.id = UUID()
        exampleResponse.answer = "Used fewer PowerPoint slides, talked slower, and been more engaging with the audience."
        exampleResponse.question = sampleQuestion
        
        return exampleResponse
    }//: ReflectionResponse
    
}//: EXTENSION

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
        } else if let recordedAudio = self.audioReflection {
            do {
                let audioPlayer = try AVAudioPlayer(data: recordedAudio)
                let recordingLength = audioPlayer.duration
                if recordingLength >= 10 {
                    self.completeAnswerYN = true
                }
            } catch {
                print("Failed to retrieve audio from data: \(error.localizedDescription)")
            }
        }//: IF - ELSE
    }//: markResponseAsComplete
    
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

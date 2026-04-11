//
//  ActivityReflectionPromptResponseRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/25/26.
//

import SwiftUI

struct ActivityReflectionPromptResponseRowView: View {
    // MARK: - PROPERTIES
    @ObservedObject var response: ReflectionResponse
    
    // MARK: - COMPUTED PROPERTIES
    
    var selectedQuestion: String {
        if let question = response.question {
            return question.promptQuestion
        } else {
            return "No Question Selected"
        }//: IF ELSE
    }//: selectedQuestion
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text(selectedQuestion)
                .foregroundStyle(.white)
                .bold()
                .frame(minHeight: 40, alignment: .center)
            
            HStack(alignment: .bottom, spacing: 5) {
                if response.hasAudioReflection {
                    Image(systemName: "waveform.and.mic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.blue)
                        .accessibilityLabel(Text("Audio reflection available"))
                        .accessibilityHint(Text("There is a recorded audio reflection for this prompt. Tap on this button to access the screen which will allow you to play it or record a new one."))
                }//: IF (hasAudioReflection)
                
                if response.completeAnswerYN {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.green)
                        .accessibilityLabel(Text("Response complete"))
                        .accessibilityHint(Text("The entered response meets the achievement criteria to be considered a complete answer for the selected prompt. Keep it up to continue earning achievement badges!"))
                }//: IF (completeAnswerYN)
            }//: HSTACK
            .padding([.vertical, .horizontal], 5)
            
        }//: HSTACK
        .frame(minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.7))
        )//: BACKGROUND
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    ActivityReflectionPromptResponseRowView(response: .example)
}

//
//  PromptResponseView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// This view is to show both a prompt and a textfield for the user to
// enter/edit their response to the question

// Parent view: ActivityReflectionView

import SwiftUI

/// Child view of ActivityReflectionView that shows the UI for entering text in response to a selected learning reflection
/// prompt.  If the response object passed in does NOT have a question value yet, then the NoItemView will be shown
/// along with a button to bring up the PromptSelectionSheet.
/// - Parameters:
///     - response: ReflectionResponse object related to the activity being reflection on (via ActivityReflectionView)
///
/// - Important: This child view does NOT actually save any changes made to the response answer field. That is
/// handled by the parent view.
struct PromptResponseView: View {
    // MARK: - PROPERTIES
    @ObservedObject var response: ReflectionResponse
    
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - COMPUTED PROPERTIES
    var formattedModDate: String {
        if let lastEdited = response.modifiedOn {
            let localString = NSLocalizedString(lastEdited.formatted(date: .numeric, time: .shortened), comment: "Day & time when the user last edited their answer to a prompt.")
            return localString
        } else {
            return "N/A (First time to respond to question!)"
        }
    }//: formattedModDate
    
    // MARK: - CLOSURES
    var onSelectPrompt: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        // TODO: Add a button and method for deleting the object
        VStack {
            // Selected prompt question  + button to change
            if let savedPrompt = response.question {
                HStack(spacing: 5) {
                    Text(savedPrompt.promptQuestion)
                    Spacer()
                    Button {
                        onSelectPrompt()
                    } label: {
                        Label("Change Prompt", systemImage: "arrow.branch")
                            .labelsHidden()
                    }//: BUTTON
                    .buttonStyle(.bordered)
                    
                }//: HSTACK
                
                Divider()
                // TextField for answering question
                // Updating field updates the modifiedOn property
                Text("Last Updated: \(formattedModDate)")
                    .foregroundStyle(.secondary)
                    .font(.caption).bold()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.gray.opacity(0.3))
                    )
                
                TextField("Enter Reflections", text: $response.responseAnswer, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 150, alignment: .topLeading)
                    .focused($isTextFieldFocused)
                
            } else {
                VStack(spacing: 10) {
                    NoItemView(
                        noItemTitleText: "No Prompt Saved",
                        noItemMessage: "Please try selecting a prompt again.",
                        noItemImage: "slash.circle"
                    )
                    
                    Button {
                        onSelectPrompt()
                    } label: {
                        Text("Select Prompt")
                    }//: BUTTON
                    .buttonStyle(.borderedProminent)
                }//: VSTACK
            }//: IF - ELSE
        }//: VSTACK
        // TODO: Verify frame dimensions look good
        .frame(minHeight: 175, idealHeight: 200, maxHeight: 450)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 3)
        )//: BACKGROUND
        // MARK: - ON CHANGE
        .onChange(of: response.answer) { _ in
            if !isTextFieldFocused {
                response.modifiedOn = Date.now
            }//: IF
        }//: ON CHANGE
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptResponseView(response: .example)
}

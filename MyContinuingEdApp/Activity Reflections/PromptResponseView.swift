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
    
    @State private var showDeleteResponseAlert: Bool = false
   
    
    // MARK: - COMPUTED PROPERTIES
   
    
    // MARK: - CLOSURES
    var onSelectPrompt: () -> Void = { }
    var onDeleteResponse: (ReflectionResponse) -> Void = { _ in }
    
    // MARK: - BODY
    var body: some View {
        // TODO: Add a button and method for deleting the object
        VStack {
            // Selected prompt question  + button to change
            if let savedPrompt = response.question {
                Group {
                    
                    PromptHeaderView(response: response, onSelectPrompt: {
                        onSelectPrompt()
                    })
                    
                    
                    
                    TextField("Enter Reflections", text: $response.responseAnswer, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: 150, alignment: .topLeading)
                        .focused($isTextFieldFocused)
                    
                    // Delete Button
                    DeleteObjectButtonView(
                        buttonText: "Delete Response",
                        onDelete: {
                            showDeleteResponseAlert = true
                        }
                    )
                }//: GROUP
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
        // TODO: Analyze potential for data races in onChange & onReceive
        // MARK: - ON CHANGE
        .onChange(of: response.answer) { _ in
            if !isTextFieldFocused {
                response.modifiedOn = Date.now
            }//: IF
        }//: ON CHANGE
        // MARK: - ON RECEIVE
        .onReceive(response.objectWillChange) { _ in
            if !isTextFieldFocused {
                Task {
                    try await Task.sleep(for: .seconds(0.1))
                    await response.markResponseAsComplete()
                }//: TASK
            }//: IF (isTextFieldFocused)
        }//: ON RECEIVE
        // MARK: - ALERTS
        .alert("Delete Response?", isPresented: $showDeleteResponseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDeleteResponse(response)
            }
        } message: {
            Text("Are you sure you wish to delete your response to this prompt? This will permanently delete both any written text and recorded audio associated with the prompt.")
        }//: ALERT

        
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptResponseView(response: .example)
}

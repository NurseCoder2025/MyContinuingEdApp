//
//  PromptHeaderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/30/26.
//

// Parent view: PromptResponseView

import SwiftUI

/// Child view of PromptResponseView that displays the text for a selected prompt along with a Text view that shows
/// the user when the prompt response was last updated.
/// - Parameters:
///     - response: ReflectionResponse object for which the prompt is to be shown
///
/// - Note: The action of the button in this view is a closure which passes up through PromptResponseView
/// and then again to the grandparent view of ActivityReflection for actual handling.
///
///  This subview consists of a VStack -> HStack with the prompt and a button for changing the prompt -> Text with the
///  last day and time modified from the response's modifiedOn property.
struct PromptHeaderView: View {
    // MARK: - PROPERTIES
    @ObservedObject var response: ReflectionResponse
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property within PromptHeaderView that returns the String assigned to a ReflectionResponse's
    /// associated ReflectionPrompt's (via the question relationship property) question property.
    /// - Returns:
    ///     - question String assigned to a ReflectionPrompt object that is saved to the ReflectionResponse's
    ///     question relationship property
    ///     - "Need Prompt" if nill
    var promptText: String {
        if let savedPrompt = response.question, let selectedQ = savedPrompt.question {
            return selectedQ
        } else {
            return "Need Prompt"
        }
    }//: promptText
    
    /// Computed property within PromptHeaderView that turns a given ReflectionResponse object's modifiedOn
    /// Date property into a localized String with a numeric date and shortened time value for displaying in a
    /// Text control so the user can see when they last modified their response.
    ///
    /// - Returns:
    ///     - Localized date string (if available)
    ///     - "N/A (First time to respond to question!)" if modifiedOn is null
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
        VStack {
            HStack(spacing: 5) {
                Text(promptText)
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
        }//: VSTACK
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptHeaderView(response: .example)
}

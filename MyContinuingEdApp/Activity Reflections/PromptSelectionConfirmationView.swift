//
//  PromptSelectionConfirmationView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

import SwiftUI

struct PromptSelectionConfirmationView: View {
    // MARK: - PROPERTIES
    @Binding var selectedPrompt: ReflectionPrompt?
    
    // MARK: - CLOSURES
    var onPromptSelection: (ReflectionPrompt) -> Void = {_ in }
    var noPromptSelected: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Divider()
            
            Button {
                if let chosenPrompt = selectedPrompt {
                    onPromptSelection(chosenPrompt)
                } else {
                    noPromptSelected()
                }
            } label: {
                Text("Save Selection")
                    .font(.title2)
            }//: BUTTON
            .buttonStyle(.borderedProminent)
        }//: VSTACK
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    PromptSelectionConfirmationView(selectedPrompt: .constant(.shortExample))
}

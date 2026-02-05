//
//  FavoritePromptSelectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// Parent view: PromptSelectionSheet

import CoreData
import SwiftUI

/// Child view of PromptSelectionSheet which displays all prompts (both built-in and user-created) that have been marked as
/// "favorites" for quick and easy reference.  Upon tapping the "Save Selection" button, the view passes a closure to
/// PromptSelectionSheet for handling.
struct FavoritePromptSelectionView: View {
    // MARK: - PROPERTIES
    @State private var selectedPrompt: ReflectionPrompt? = nil
    
    // MARK: - CORE DATA
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "question", ascending: true)],
        predicate: NSPredicate(format: "favoriteYN == true")
    ) var favoritePrompts: FetchedResults<ReflectionPrompt>
    
    // MARK: - CLOSURES
    var onPromptSelection: (ReflectionPrompt) -> Void = {_ in }
    var noPromptSelected: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        VStack {
            TabView {
                ForEach(favoritePrompts) {prompt in
                    PromptCardView(prompt: prompt)
                        .onTapGesture {
                            selectedPrompt = prompt
                        }//: ON TAP
                        .onTapGesture(count: 2) {
                            selectedPrompt = nil
                        }//: ON DOUBLE TAP
                    
                }//: LOOP
            }//: TAB
            .tabViewStyle(.page)
            .frame(height: 300)
            
           PromptSelectionConfirmationView(
            selectedPrompt: $selectedPrompt,
            onPromptSelection: { prompt in
                onPromptSelection(prompt)
            },
            noPromptSelected: {noPromptSelected()}
           )
            
        }//: VSTACK
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEw
#Preview {
    FavoritePromptSelectionView()
}

//
//  StandardPromptSelectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// Parent view: PromptSelectionSheet

import CoreData
import SwiftUI

/// Child view of PromptSelectionSheet which displays all built-in ReflectionPrompt objects, which were generated from
/// the "Reflection Prompts.json" file within the app bundle.  Upon tapping the "Save Selection" button, the view passes
/// a closure to PromptSelectionSheet for processing.
struct StandardPromptSelectionView: View {
    // MARK: - PROPERTIES
    @State private var selectedPrompt: ReflectionPrompt? = nil
    
    // MARK: - CORE DATA
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "question", ascending: true)],
        predicate: NSPredicate(format: "customYN == false")
    ) var standardPrompts: FetchedResults<ReflectionPrompt>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "categoryName", ascending: true)]) var promptCategories: FetchedResults<PromptCategory>
    
    // MARK: - CLOSURES
    var onPromptSelection: (ReflectionPrompt) -> Void = {_ in }
    var noPromptSelected: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        LazyVStack {
            ForEach(promptCategories) { category in
                DisclosureGroup(category.catName) {
                    TabView {
                        ForEach(category.assignedPrompts) {prompt in
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
                }//: DISCLOSURE GROUP
            }//: LOOP
            
           PromptSelectionConfirmationView(
            selectedPrompt: $selectedPrompt,
            onPromptSelection: { prompt in
                onPromptSelection(prompt)
            },
            noPromptSelected: {noPromptSelected()}
           )
            
        }//: LAZY VSTACK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    StandardPromptSelectionView()
}

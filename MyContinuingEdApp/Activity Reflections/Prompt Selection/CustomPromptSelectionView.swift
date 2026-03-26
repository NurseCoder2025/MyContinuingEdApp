//
//  CustomPromptSelectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// Parent view: PromptSelectionSheet

import CoreData
import SwiftUI

/// Child view of PromptSelectionSheet which displays all user-made prompts (Pro subscription ONLY). Upon tapping the
/// "Save Selection" button, the view passes a closure to PromptSelectionSheet for handling.
struct CustomPromptSelectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @State private var selectedPrompt: ReflectionPrompt? = nil
    
    // MARK: - CORE DATA
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "question", ascending: true)],
        predicate: NSPredicate(format: "customYN == true")
    ) var customPrompts: FetchedResults<ReflectionPrompt>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "categoryName", ascending: true)]) var promptCategories: FetchedResults<PromptCategory>
    
    // MARK: - COMPUTED PROPERTIES
    
    var categoriesWithPrompts: [PromptCategory] {promptCategories.filter { $0.hasCustomPrompts }}//: categoriesWithPrompts
    
    // MARK: - CLOSURES
    var onPromptSelection: (ReflectionPrompt) -> Void = {_ in }
    var noPromptSelected: () -> Void = { }
    var onCreateCustomPrompt: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        if categoriesWithPrompts.isEmpty {
            VStack {
                NoItemView(
                    noItemTitleText: "No Custom Prompts Yet...",
                    noItemMessage: "You haven't created any custom prompts yet. Get started today!",
                    noItemImage: "slash.circle"
                )//: NoItemView
                
                Button {
                    onCreateCustomPrompt()
                    dataController.checkForNewAchievements()
                } label: {
                    Text("Create custom prompt")
                }//: BUTTON
            }//: VSTACK
        } else {
            LazyVStack {
                ForEach(categoriesWithPrompts) { category in
                    DisclosureGroup(category.catName) {
                        TabView {
                            ForEach(category.assignedCustomPrompts) {prompt in
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
                
            }//:LazyVSTACK
        }//: IF ELSE
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CustomPromptSelectionView()
}

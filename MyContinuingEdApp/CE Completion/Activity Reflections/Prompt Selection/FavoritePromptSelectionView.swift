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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "categoryName", ascending: true)]) var promptCategories: FetchedResults<PromptCategory>
    
    // MARK: - COMPUTED PROPERTIES
    
    var categoriesWithFavorites: [PromptCategory] {promptCategories.filter {$0.hasFavoritePrompts}}//: categoriesWithFavories
    
    // MARK: - CLOSURES
    var onPromptSelection: (ReflectionPrompt) -> Void = {_ in }
    var noPromptSelected: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        if categoriesWithFavorites.isEmpty {
            NoItemView(
                noItemTitleText: "No Favorites Yet...",
                noItemMessage: "You haven't marked any prompts as favorites yet.  Tap the star button in the top-right corner to add some!",
                noItemImage: "star.slash.fill"
            )//: NoItemView
        } else {
            LazyVStack {
                ForEach(categoriesWithFavorites) { category in
                    DisclosureGroup(category.catName) {
                        TabView {
                            ForEach(category.assignedFavoritePrompts) {prompt in
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
                
            }//: LazyVSTACK
        }//: IF ELSE
    }//: BODY
}//: STRUCT

// MARK: - PREVIEw
#Preview {
    FavoritePromptSelectionView()
}

//
//  CustomPromptCreationView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/25/26.
//

import CoreData
import SwiftUI

struct CustomPromptCreationSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @State private var promptText: String = ""
    @State private var selectedCategory: PromptCategory?
    @State private var promptIsFavorite: Bool = false
    
    @State private var showNoCategoryAssignedAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    var appPurchaseStatus: PurchaseStatus {
        let currentStatus = dataController.purchaseStatus
        if currentStatus == PurchaseStatus.proSubscription.id {
            return PurchaseStatus.proSubscription
        } else if currentStatus == PurchaseStatus.basicUnlock.id {
            return PurchaseStatus.basicUnlock
        } else {
            return PurchaseStatus.free
        }//: IF ELSE
    }//: appPurchaseStatus
    
    // MARK: - CORE DATA
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "categoryName", ascending: true)]) var promptCategories: FetchedResults<PromptCategory>
    
    // MARK: - BODY
    var body: some View {
        VStack {
            TextField("Custom prompt:", text: $promptText, axis: .vertical)
                .frame(minHeight: 50)
            
            Group {
                Text("Prompt Category:")
                    .font(.headline)
                Text("Note: A selected category is required for all custom prompts in order for it to be saved.")
                    .font(.caption)
                Picker("Prompt Category", selection: $selectedCategory) {
                    Text("")
                    ForEach(promptCategories) { cat in
                        Text(cat.catName).tag(cat)
                    }//: LOOP
                }//: PICKER
                .pickerStyle(.wheel)
            }//: Group
            
            if appPurchaseStatus != .free {
                Toggle("Mark Prompt as Favorite?", isOn: $promptIsFavorite)
            }//: IF (!= .free)
            
            // MARK: - SAVE BUTTON
            Button {
               saveCustomPrompt()
            } label: {
                Text("Save Custom Prompt")
            }//: BUTTON
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)
            
        }//: VSTACK
        .navigationTitle(Text("Create Custom Prompt"))
        // MARK: - TOOlBAR
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Dismiss")
                }//: BUTTON
            }//: TOOLBAR ITEM
            
        }//: TOOLBAR
        // MARK: - ALERTS
        .alert("No Category Assigned", isPresented: $showNoCategoryAssignedAlert) {
            Button("OK"){}
        } message: {
            Text("You need to select a prompt category before saving.")
        }//: ALERT

        
    }//: BODY
    // MARK: - METHODs
    
    private func saveCustomPrompt() {
        guard selectedCategory != nil else {
            showNoCategoryAssignedAlert = true
            return
        }//: GUARD
        let newPrompt = dataController.createNewCustomPrompt(with: promptText, for: selectedCategory)
         if promptIsFavorite {
             newPrompt.favoriteYN = true
         }
         dataController.save()
         dismiss()
    }//: saveCustomPrompt()
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CustomPromptCreationSheet()
}

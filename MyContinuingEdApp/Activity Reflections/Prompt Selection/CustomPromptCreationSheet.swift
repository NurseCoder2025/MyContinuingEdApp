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
    
    // MARK: - COMPUTED PROPERTIEs
    
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
               let newPrompt = dataController.createNewCustomPrompt(with: promptText, for: selectedCategory)
                if promptIsFavorite {
                    newPrompt.favoriteYN = true
                }
                dataController.save()
                dismiss()
            } label: {
                Text("Save Custom Prompt")
            }//: BUTTON
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)
            
        }//: VSTACK
        .navigationTitle(Text("Create Custom Prompt"))
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CustomPromptCreationSheet()
}

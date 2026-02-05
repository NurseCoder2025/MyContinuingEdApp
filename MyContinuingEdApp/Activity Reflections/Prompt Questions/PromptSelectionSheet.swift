//
//  PromptSelectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// This view is to hold UI controls for the user to select the specific
// reflection prompt that they wish to answer

// Calling view: ActivityReflectionView

import SwiftUI

/// Sheet used to allow the user to select a specific learning reflection prompt to write on in within an ActivityReflection
/// object (or, rather, the ActivityReflectionView).  A PromptView enum allows the user to cycle through different sets of
/// possible prompts (only for paid users - free users only get the standard set).
/// - Parameters:
///     - reflection: ActivityReflection object representing a CE activity that the user wishes to reflect upon
struct PromptSelectionSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var reflection: ActivityReflection
    
    @State private var selectedView: PromptView = .builtInPrompts
    @State private var showPromptSelectionErrorAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    var appPaidStatus: PurchaseStatus {
        let statusString = dataController.purchaseStatus
        switch statusString {
        case "basicUnlock":
            return PurchaseStatus.basicUnlock
        case "proSubscription":
            return PurchaseStatus.proSubscription
        default:
            return PurchaseStatus.free
        }//: SWITCH
    }//: appPaidStatus
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // Control for selecting the type of prompt (built-in, custom, favorite)
            Picker("Prompt Selection", selection: $selectedView) {
                ForEach(PromptView.allCases) {viewType in
                    Text(viewType.id).tag(viewType)
                }//: LOOP
            }//: PICKER
            .pickerStyle(.segmented)
            
            Divider()
            
            // Displaying the appropriate prompt view based on selection
            // Sub-views should be buttons that create a new Response
            // using the Reflection from the parent view
            switch selectedView {
                case .builtInPrompts:
                    StandardPromptSelectionView(
                        onPromptSelection: { prompt in
                            dataController.createNewPromptResponse(
                                using: prompt,
                                for: reflection
                            )//: createNewPromptResponse
                        },
                        noPromptSelected: {
                            showPromptSelectionErrorAlert = true
                        }
                    )
                case .userMadePrompts:
                    if appPaidStatus != .proSubscription {
                        PaidFeaturePromoView(
                            featureIcon: "text.word.spacing",
                            featureItem: "Custom Prompts",
                            featureUpgradeLevel: .ProOnly,
                        )
                    } else {
                        CustomPromptSelectionView(
                            onPromptSelection: {prompt in
                                dataController.createNewPromptResponse(
                                    using: prompt,
                                    for: reflection
                                )
                             
                            },//: onPromptSelection
                            noPromptSelected: {
                                showPromptSelectionErrorAlert = true
                            }
                         )
                    }//: IF - ELSE
                
                case .favoritePrompts:
                    if appPaidStatus == .free {
                        PaidFeaturePromoView(
                            featureIcon: "text.word.spacing",
                            featureItem: "Favorite Prompts",
                            featureUpgradeLevel: .basicAndPro,
                        )
                    } else {
                        FavoritePromptSelectionView(
                            onPromptSelection: {prompt in
                                dataController.createNewPromptResponse(
                                    using: prompt,
                                    for: reflection
                                )
                             
                            },//: onPromptSelection
                            noPromptSelected: {
                                showPromptSelectionErrorAlert = true
                            }
                        )
                    }//: IF - ELSE
                    
            }//: SWITCH
        }//: VSTACK
        .navigationTitle("Prompt Selection")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - TOOLBAR
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    // Introducing a slight delay in order to ensure that if the user
                    // has actually selected a prompt and a new ReflectionResponse object
                    // was created, that the system has time to save it to the context so
                    // that the UI in the parent view will show the appropriate UI controls
                    // for that.
                    Task {@MainActor in
                        // TODO: Adjust the # of seconds as needed to ensure it isn't too long
                        try await Task.sleep(for: .seconds(0.1))
                        dismiss()
                    }
                } label: {
                    Text("Dismiss")
                }//: BUTTON
            }//: TOOLBAR ITEM
            
        }//: TOOLBAR
        // MARK: - ALERTS
        .alert("Selection Error", isPresented: $showPromptSelectionErrorAlert) {
        } message: {
            Text("No prompt was selected. Try again by tapping once on the prompt you wish to use for your activity reflection.")
        }//: ALERT
        // MARK: - ON RECIEVE
        .onReceive(reflection.objectWillChange) { _ in
            dismiss()
        }//: ON RECIEVE
        
    }//: BODY
    // MARK: - METHODS
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptSelectionSheet(reflection: .example)
}

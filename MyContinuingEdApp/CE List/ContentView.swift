//
//  ContentView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController

    @Environment(\.spotlightCentral) var spotlightCentral
    @StateObject private var viewModel: ViewModel
    
    @State private var showUpgradetoPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus? = nil
    
    var deletionWarningMessage: String = ""
    
    // MARK: - BODY
    var body: some View {
            /// The List section displays the ActivityROW and not the ActivityView. The
            /// ActivityView struct is for showing the details of each activity.
        List(selection: $viewModel.dataController.selectedActivity) {
            
                // MARK: Header section
            ForEach(viewModel.sortedKeys, id: \.self) { key in
                    Section(header: Text(key)) {
                        
                        // MARK: Ce Activity row under the key header
                        ForEach(viewModel.dataController.activitiesBeginningWith(letter: key)) { activity in
                            ActivityRow(activity: activity)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.delete(activity: activity)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }//: BUTTON
                                }//: SWIPE
                        } //: LOOP
                        
                    }//: SECTION
                }//: LOOP
            } //: LIST
            .navigationTitle("CE Activities")
            .searchable(
                text: $viewModel.dataController.filterText,
                tokens: $viewModel.dataController.filterTokens,
                suggestedTokens: .constant(viewModel.dataController.suggestedFilterTokens),
                prompt: "Filter CE activities, or type # to add tags") { tag in
                Text(tag.tagTagName)
            }
        // MARK: - ALERTS
                .alert("CE Activity Deletion Warning", isPresented: $viewModel.showDeleteWarning) {
                Button("Delete", role: .destructive) {
                    if let activity = viewModel.activityToDelete {
                        if #available(iOS 17, *) {
                            viewModel.dataController.delete(activity)
                        } else {
                            spotlightCentral?.removeCeActivityFromDefaultIndex(activity)
                            viewModel.dataController.delete(activity)
                        }//: IF AVAILABLE
                    }//: IF LET
                    
                    viewModel.activityToDelete = nil
                } //: DELETE button
                
                Button("Cancel", role: .cancel) {
                    viewModel.activityToDelete = nil
                }
            } message: {
                if let activity = viewModel.activityToDelete {
                    Text("Warning! You are about to delete the activity '\(activity.ceTitle)'.  This will delete its certificate along with any reflections.  This action cannot be undone.")
                }
            }
            // MARK: - TOOLBAR
            .toolbar {
                ContentViewToolbarView() {
                    if #available(iOS 17, *) {
                        // Use the dataController's createActivity method and item
                        // will be automatically added to Spotlight's index
                        do {
                            try dataController.createActivity()
                        } catch  {
                            showUpgradetoPaidSheet = true
                        }
                        
                    } else {
                        // Manually add CeActivity to Spotlight's index
                        do {
                            let newCe = try dataController.createNewCeActivityIOs16()
                            spotlightCentral?.addCeActivityToDefaultIndex(newCe)
                        } catch  {
                            showUpgradetoPaidSheet = true
                        }
                    }
                }//: CLOSURE
            } //: TOOLBAR
        // MARK: - SHEETS
            .sheet(isPresented: $showUpgradetoPaidSheet) {
                UpgradeToPaidSheet(itemMaxReached: "CE activities")
            }//: SHEET
        
        
    } //: BODY
    
    // MARK: - INIT
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
    
    
}//: STRUCT


// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dataController: .preview)
    }
}

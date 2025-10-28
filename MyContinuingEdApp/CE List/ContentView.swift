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
    @StateObject private var viewModel: ViewModel
   
    let activityDeleteWarning: String = """
    WARNING: You are about to delete a CE activity along with 
    any reflections attached to it.  Are you sure you want to delete?  
    This cannot be undone.
    """
    
    
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
                .alert("CE Activity Deletion Warning", isPresented: $viewModel.showDeleteWarning) {
                Button("Delete", role: .destructive) {
                    if let activity = viewModel.activityToDelete {
                        viewModel.dataController.delete(activity)
                    }
                    viewModel.activityToDelete = nil
                } //: DELETE button
                
                Button("Cancel", role: .cancel) {
                    viewModel.activityToDelete = nil
                }
            } message: {
                Text(activityDeleteWarning)
            }
            // MARK: - TOOLBAR
            .toolbar {ContentViewToolbarView()} //: TOOLBAR
        
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

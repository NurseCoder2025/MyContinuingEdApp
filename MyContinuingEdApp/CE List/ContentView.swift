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
    
    // Properties for warning users about deleting a CE activity
    @State private var showDeleteWarning: Bool = false
    @State private var activityToDelete: CeActivity?
    let activityDeleteWarning: String = """
    WARNING: You are about to delete a CE activity along with 
    any reflections attached to it.  Are you sure you want to delete?  
    This cannot be undone.
    """
    
    // MARK: - COMPUTED PROPERTIES
    
    var computedCEActivityList: [CeActivity] {dataController.activitiesForSelectedFilter()}
    
    /// Computed property used to create headings in the list of CeActivities based on the first letter of each activity so that all activities are grouped
    /// alphabetically
    var alphabeticalCEGroupings: [String : [CeActivity]] {
        Dictionary(grouping: computedCEActivityList) { activity in
            String(activity.ceTitle.prefix(1).uppercased())
        }
    }//: alphabeticalCEGroupings
    
    /// Computed property that returns a string of all letters present in entered CeActivities (keys in the alphabeticalCEGroupings property)
    var sortedKeys: [String] {
        alphabeticalCEGroupings.keys.sorted()
    }
    
    // MARK: - BODY
    var body: some View {
            /// The List section navigates to the ActivityROW and not the ActivityView. The
            /// ActivityView struct is for showing the details of each activity.
            List(selection: $dataController.selectedActivity) {
                // MARK: Header section
                ForEach(sortedKeys, id: \.self) { key in
                    Section(header: Text(key)) {
                        // MARK: Ce Activity row under the key header
                        ForEach(dataController.activitiesForSelectedFilter()) { activity in
                            ActivityRow(activity: activity)
                        } //: LOOP
                        .onDelete(perform: delete)
                    }//: SECTION
                }//: LOOP
            } //: LIST
            .navigationTitle("CE Activities")
            .searchable(
                text: $dataController.filterText,
                tokens: $dataController.filterTokens,
                suggestedTokens: .constant(dataController.suggestedFilterTokens),
                prompt: "Filter CE activities, or type # to add tags") { tag in
                Text(tag.tagTagName)
            }
            .alert("CE Activity Deletion Warning", isPresented: $showDeleteWarning) {
                Button("Delete", role: .destructive) {
                    if let activity = activityToDelete {
                        dataController.delete(activity)
                    }
                    activityToDelete = nil
                } //: DELETE button
                
                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                }
            } message: {
                Text(activityDeleteWarning)
            }
            // MARK: - TOOLBAR
            .toolbar {ContentViewToolbarView()} //: TOOLBAR
        
    } //: BODY
    
    // MARK: - ContentView Methods
    func delete(_ offsets: IndexSet) {
        let activities = dataController.activitiesForSelectedFilter()
        
        for offset in offsets {
            let item = activities[offset]
            activityToDelete = item
        }
        
        showDeleteWarning = true
    } //: DELETE Method
    
}


// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataController(inMemory: true))
            
    }
}

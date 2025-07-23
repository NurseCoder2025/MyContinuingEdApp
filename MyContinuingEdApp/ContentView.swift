//
//  ContentView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController
    
    
    
    
    // MARK: - BODY
    var body: some View {
        /// The List section navigates to the ActivityROW and not the ActivityView. The
        /// ActivityView struct is for showing the details of each activity.
        List(selection: $dataController.selectedActivity) {
            ForEach(dataController.activitiesForSelectedFilter()) { activity in
                ActivityRow(activity: activity)
            } //: LOOP
            .onDelete(perform: delete)
            
        } //: LIST
        .navigationTitle("CE Activities")
        .searchable(text: $dataController.filterText, tokens: $dataController.filterTokens, suggestedTokens:  .constant(dataController.suggestedFilterTokens), prompt: "Filter CE activities, or type # to add tags") { tag in
                Text(tag.tagTagName)
        }
    }
    
    // MARK: - ContentView Methods
    func delete(_ offsets: IndexSet) {
        let activities = dataController.activitiesForSelectedFilter()
        
        for offset in offsets {
            let item = activities[offset]
            dataController.delete(item)
        }
    } //: DELETE Method
}


// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

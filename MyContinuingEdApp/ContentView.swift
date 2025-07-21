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
    
    // Computed property to retun all activities as determined by active filters and selected tag
    var activitiesToShow: [CeActivity] {
        let filter = dataController.selectedFilter ?? .allActivities
        var allActivities: [CeActivity]
        
        if let tag = filter.tag {
            // Type casting to CeActivity becuase tag objects are stored as NSSet data types in Core Data
            allActivities = tag.tags_activities?.allObjects as? [CeActivity] ?? []
        } else {
            // Defining the fetch request and predicate
            let request = CeActivity.fetchRequest()
            request.predicate = NSPredicate(format: "modifiedDate > %@", filter.minModificationDate as NSDate)
            
            // Running the fetch request and assigning the results to allActivities
            allActivities = (try? dataController.container.viewContext.fetch(request)) ?? []
        }
        
        return allActivities.sorted()
    }
    
    
    // MARK: - BODY
    var body: some View {
        /// The List section navigates to the ActivityROW and not the ActivityView. The
        /// ActivityView struct is for showing the details of each activity.
        List(selection: $dataController.selectedActivity) {
            ForEach(activitiesToShow) { activity in
                ActivityRow(activity: activity)
            } //: LOOP
            .onDelete(perform: delete)
            
        } //: LIST
        .navigationTitle("CE Activities")
    }
    
    // MARK: - ContentView Methods
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = activitiesToShow[offset]
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

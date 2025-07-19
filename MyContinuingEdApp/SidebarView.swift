//
//  SidebarView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI

struct SidebarView: View {
    // MARK: - PROPERTIES
    // Accessing the data controller environmental object
    @EnvironmentObject var dataController: DataController
    
    // Defining smart filters
    let smartFilters: [Filter] = [.allActivities, .recentActivities]
    
    // Converting all fetched tags to Filter objects
    var convertedTagFilters: [Filter] {
        tags.map { tag in
            Filter(name: tag.tagTagName, icon: "tag", tag: tag)
        }
    }
    
    // MARK: - Core Data fetch requests
    // All tags sorted by name
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tagName)]) var tags: FetchedResults<Tag>
    
    
    // MARK: - BODY
    var body: some View {
        List(selection: $dataController.selectedFilter) {
            Section("Smart Filters") {
                ForEach(smartFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                    } //: NAV LINK
                    
                } //: LOOP
            } //: SECTION (smart filters)
            
            Section("Tags") {
                ForEach(convertedTagFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                            .badge(filter.tag?.tagActiveActivities.count ?? 0)
                    } //: NAV LINK
                } //: LOOP
                .onDelete(perform: delete)
                
            } //: SECTION (tags)
            
            
        } //: LIST
        .toolbar {
            Button {
                dataController.deleteAll()
                dataController.createSampleData()
            } label: {
                Label("Add Samples", systemImage: "flame")
            }
        }
    } //: BODY
    
    // MARK: - View Functions
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = tags[offset]
            dataController.delete(item)
        }
    } //: DELETE method
}



// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}

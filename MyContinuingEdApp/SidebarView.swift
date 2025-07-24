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
    
    // Properties for renaming tags
    @State private var showRenamingAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var tagToRename: Tag?
    
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
                            .contextMenu {
                                Button {
                                    renameTag(filter)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }//: CONTEXT MENU

                            } //: NAV LINK
                    } //: LOOP
                    .onDelete(perform: delete)
                    
                } //: SECTION (tags)
                
                
            } //: LIST
            .toolbar {
                Button(action: dataController.createNewTag) {
                    Label("Add Tag", systemImage: "plus")
                }
                
                
            #if DEBUG
                Button {
                    dataController.deleteAll()
                    dataController.createSampleData()
                } label: {
                    Label("Add Samples", systemImage: "flame")
                }
            #endif
                
            } //: TOOLBAR
            .alert("Rename Tag", isPresented: $showRenamingAlert) {
                Button("OK", action: confirmTagRename)
                Button("Cancel", role: .cancel) {}
                TextField("New tag name:", text: $newTagName)
            }
        } //: BODY
        
        // MARK: - View Functions
        func delete(_ offsets: IndexSet) {
            for offset in offsets {
                let item = tags[offset]
                dataController.delete(item)
            }
        } //: DELETE method
        
        func renameTag(_ selectedFilter: Filter) {
            tagToRename = selectedFilter.tag
            newTagName = selectedFilter.name
            showRenamingAlert = true
        }
        
        func confirmTagRename() {
            tagToRename?.tagName = newTagName
            dataController.save()
        }
        
    } //: STRUCT
    

// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}

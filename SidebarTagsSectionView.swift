//
//  SidebarTagsSectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//


// Purpose: To encapsulate UI and behavior related to user-created tags in SidebarView

import CoreData
import SwiftUI

struct SidebarTagsSectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // Callback for renaming tag
    var onRenameTag: (Filter) -> Void
    

    // MARK: - COMPUTED PROPERTIES
    
    // Converting all fetched tags to Filter objects
    var convertedTagFilters: [Filter] {
        tags.map { tag in
            Filter(name: tag.tagTagName, icon: "tag", tag: tag)
        }
    }//: convertedTagFilters
    
    // MARK: - CORE DATA FETCHES
    // All tags sorted by name
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tagName)]) var tags: FetchedResults<Tag>
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                ForEach(convertedTagFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                            .badge(filter.tagActivitiesCount)
                            .contextMenu {
                                // Renaming tag button
                                Button {
                                   onRenameTag(filter)
                                } label: {
                                    Label("Rename tag", systemImage: "pencil")
                                }
                                
                                // Deleting tag button
                                Button(role: .destructive) {
                                    deleteTag(filter)
                                } label: {
                                    Label("Delete tag", systemImage: "trash")
                                }//: BUTTON
                                
                            }//: CONTEXT MENU
                            .accessibilityElement()
                            .accessibilityLabel("Tag: \(filter.name)")
                            .accessibilityHint("^[\(filter.tagActivitiesCount) activity] (inflect: true)")
                        
                    } //: NAV LINK
                } //: LOOP
            } header: {
                HStack {
                    Text("Tags")
                    Spacer()
                    
                    // New tag creation button
                    Button{
                        dataController.createNewTag()
                    } label: {
                        Label("New tag", systemImage:"plus")
                            .labelStyle(.iconOnly)
                    }
                    .padding(.trailing, 20)
                    
                } //: HSTACK
            } //: SECTION (tags)
        }//: GROUP
       
        
    }//: BODY
    
    // MARK: - FUNCTIONS
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = tags[offset]
            dataController.delete(item)
        }
    } //: DELETE method
    
    /// This function is for deleting individual tag objects that the user created in SidebarView.  A single filter object with
    /// a tag property is to be passed into the function, which in turn will delete the filter IF there is a tag property.
    /// - Parameter filter: Filter object representing a user-created Tag that is to be deleted
    func deleteTag(_ filter: Filter) {
        guard let tag = filter.tag else {return}
        dataController.delete(tag)
        dataController.save()
    }
    
    
    
}//: STRUCT

// MARK: - PREVIEW

//
//  SidebarTagsSectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//


// Purpose: To encapsulate UI and behavior related to user-created tags in SidebarView

import SwiftUI

struct SidebarTagsSectionView: View {
    // MARK: - PROPERTIES
    @StateObject private var viewModel: ViewModel
    
    // Callback for renaming tag
    var onRenameTag: (Filter) -> Void
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                ForEach(viewModel.convertedTagFilters) { filter in
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
                                    viewModel.deleteTag(filter)
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
                        viewModel.dataController.createNewTag()
                    } label: {
                        Label("New tag", systemImage:"plus")
                            .labelStyle(.iconOnly)
                    }
                    .padding(.trailing, 20)
                    
                } //: HSTACK
            } //: SECTION (tags)
        }//: GROUP
       
        
    }//: BODY
    
   
    
    // MARK: - INIT
    init(dataController: DataController, onRenameTag: @escaping (Filter) -> Void) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.onRenameTag = onRenameTag
    }//:INIT
    
}//: STRUCT

// MARK: - PREVIEW

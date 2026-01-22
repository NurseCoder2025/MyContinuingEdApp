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
    @EnvironmentObject var dataController: DataController
    @StateObject private var viewModel: ViewModel
    
    @State private var tagBadgeNumber: Int = 0
    
    // MARK: - CLOSURES
    // Callback for renaming tag
    var onRenameTag: (Filter) -> Void
    
    // Closure for creating a new tag
    var onCreateNewTag: () -> Void
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                ForEach(viewModel.convertedTagFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.tag?.tagName ?? "Unnamed", systemImage: filter.icon)
                        // MARK: BADGE
                            .badge(tagBadgeNumber)
                        // MARK: - CONTEXT MENU
                            .contextMenu {
                                // Renaming tag button
                                Button {
                                   onRenameTag(filter)
                                } label: {
                                    Label("Rename tag", systemImage: "pencil")
                                }
//                                
                                // Deleting tag button
                                Button(role: .destructive) {
                                    viewModel.deleteTag(filter)
                                } label: {
                                    Label("Delete tag", systemImage: "trash")
                                }//: BUTTON
//                                
                            }//: CONTEXT MENU
                            .accessibilityElement()
                            .accessibilityLabel("Tag: \(filter.name)")
                            .accessibilityHint("^[\(tagBadgeNumber) activity](inflect: true)")
                        // MARK: - TASK
                            .task {
                                tagBadgeNumber = await  viewModel.getCEsCountFor(filter: filter)
                            }//: TASK
                        
                    } //: NAV LINK
                } //: LOOP
                // MARK: - HEADER
            } header: {
                HStack {
                    Text("Tags")
                    Spacer()
                    
                    // New tag creation button
                    Button{
                        onCreateNewTag()
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
    init(dataController: DataController, onRenameTag: @escaping (Filter) -> Void, onCreateNewTag: @escaping () -> Void) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.onRenameTag = onRenameTag
        self.onCreateNewTag = onCreateNewTag
    }//:INIT
    
}//: STRUCT


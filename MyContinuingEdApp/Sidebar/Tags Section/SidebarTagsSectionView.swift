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
                  TagRowLabelView(
                    filter: filter,
                    onDeleteTag: { filter in
                        viewModel.deleteTag(filter)
                    },
                    onRenameTag: onRenameTag
                  )
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


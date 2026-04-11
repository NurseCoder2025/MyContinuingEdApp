//
//  TagRowLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/26/26.
//

import SwiftUI

/// Child view in SidebarTagsSectionView that displays the label and badge icon for a given Tag object
/// that has been passed in as a Filter object.
///
/// Prior to loading, a task modiifer on the Label is executed which first fetches the tag badge count preference
/// from the sharedSettings property (via the async tagBadgeCountFor computed property) and then uses that
/// preference to call one of the three corresponding Tag computed properties which return an Int for the number
/// of CeActivity objects in the returned array.  If no objects are present then 0 is returned.
///
/// The three possible badge values are:
/// - All CeActivity objects assigned to the tag
/// - Only CeActivity objects which can still be completed, OR
/// - Only completed CeActivity objects (those marked as completed via the completedYN property)
///
/// - Note: This subview also contains the context menu and screen reader elements for accessibility purposes.
///
struct TagRowLabelView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @State private var labelBadge: Int = 0
    
    let filter: Filter
    
    // MARK: - COMPUTED PROPERTIES
    var labelText: String {filter.tag?.tagTagName ?? "Unnamed"}//: labelText
    
    // MARK: - CLOSURES
    var onDeleteTag: (Filter) -> Void = {_ in }
    var onRenameTag: (Filter) -> Void = {_ in }
    
    // MARK: - BODY
    var body: some View {
        NavigationLink(value: filter) {
            Label(labelText, systemImage: filter.icon)
                .badge(labelBadge)
            // MARK: - CONTEXT MENU
                .contextMenu {
                    // Renaming tag button
                    Button {
                       onRenameTag(filter)
                    } label: {
                        Label("Rename tag", systemImage: "pencil")
                    }
        
                    // Deleting tag button
                    Button(role: .destructive) {
                        onDeleteTag(filter)
                    } label: {
                        Label("Delete tag", systemImage: "trash")
                    }//: BUTTON
                   
                }//: CONTEXT MENU
                .accessibilityElement()
                .accessibilityLabel("Tag: \(filter.name)")
                .accessibilityHint("^[\(labelBadge) activity](inflect: true)")
            // MARK: - TASK
                .task {
                    let badgeCountPreference = await dataController.tagBadgeCountFor
                    let count: Int
                    
                    if badgeCountPreference == BadgeCountOption.activeItems.rawValue {
                        count = filter.tag?.tagActiveActivities.count ?? 0
                    } else if badgeCountPreference == BadgeCountOption.completedItems.rawValue {
                        count = filter.tag?.tagCompletedActivities.count ?? 0
                    } else {
                        count = filter.tag?.tagAllActivities.count ?? 0
                    }
                    
                    await MainActor.run {labelBadge = count}
                }//: TASK
        }//: NAVLINK
    }//: BODY
}//: TagRowLabelView

// MARK: - PREVIEW
#Preview {
    TagRowLabelView(
        filter: .allActivities
    )
}

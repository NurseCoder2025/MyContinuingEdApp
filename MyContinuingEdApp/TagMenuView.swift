//
//  TagMenuView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: To create the UI controls for part of ActivityView, making the overall
// code more maintanable

import SwiftUI

struct TagMenuView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                // MARK: Tag Menu
                Menu {
                    // Selected tags
                    ForEach(activity.activityTags) { tag in
                        Button {
                            // Tapping button will remove tag for the specific activity and into the "missing tags" set
                            activity.removeFromTags(tag)
                        } label: {
                            Label(tag.tagTagName, systemImage: "checkmark")
                        } //: Button + Label
                        
                    }//: LOOP
                    
                    
                    // Unselected tags
                    let remainingTags = dataController.missingTags(from: activity)
                    
                    if remainingTags.isNotEmpty {
                        Divider()
                        
                        Section("Add Tags") {
                            ForEach(remainingTags) { tag in
                                Button {
                                    activity.addToTags(tag)
                                } label: {
                                    Text(tag.tagTagName)
                                } //: BUTTON + label
                                
                            } //: LOOP
                            
                        } //: SECTION
                    } //: IF Statement
                    
                    
                } label: {
                    Text(activity.allActivityTagString)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil, value: activity.allActivityTagString)
                } //: MENU + Label
                
            }//: SECTION
        }//: GROUP
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    TagMenuView(activity: .example)
}

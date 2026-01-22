//
//  GeneralUISettingsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/22/26.
//

import SwiftUI

/// Child view for SettingsSheet which contains a GroupBox holding controls that relate to general UI preferences.
/// Currently, the only setting here is for the Tag badge indicator, but more can be added.
///
/// Prior to loading, the struct runs a background task which calls the async tagBadgeCountFor getter computed
/// property in DataController-Settings and compares that value to the default value assigned to the view's
/// State property tagCounterType.  If they differ, then the tagBadgeCountFor value is assigned to tagCounterType.
struct GeneralUISettingsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    /// Private state property for GeneralUISettingsView that holds a String representing what value the user
    /// wishes to be shown in the Tag badge in SidebarView. All values are controlled via the BadgeCountOption
    /// enum (as String raw values).
    ///
    /// Choices include: all assigned CEs (allItems), CEs that the user can still complete (activeItems), and
    ///  completed CEs (completedCEs).
    ///  - Important: Whenever this value changes the DataController's setTagBadgeCount(to) method is
    ///  called, and the argument that is passed must be oneof the BadgeCountOption enum raw values.  Anything else
    ///  and the method will return without changing the value in the sharedSettings key.
    @State private var tagCounterType: String = BadgeCountOption.allItems.rawValue
    
    // MARK: - BODY
    var body: some View {
        GroupBox {
            VStack {
                Text("Tag Activity Indicator")
                    .font(.headline).bold()
                    .padding(.bottom, 5)
                
                Text("This setting determines what number is shown for each custom Tag on the CE Filters sidebar. You can choose to either have the total count, just the number of completed CEs for each tag, or the number of CEs that can still be completed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                Picker("Tag Activity Count", selection: $tagCounterType) {
                    ForEach(BadgeCountOption.allCases) { option in
                        Text(option.labelText).tag(option.rawValue)
                    }//: LOOP
                }//: PICKER
                // TODO: Decide on picker style
                .pickerStyle(.menu)
                
                if tagCounterType == BadgeCountOption.allItems.rawValue {
                    Text(allTagBadgeExamples[0].explaination)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                } else if tagCounterType == BadgeCountOption.activeItems.rawValue {
                    Text(allTagBadgeExamples[1].explaination)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Text(allTagBadgeExamples[2].explaination)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }//: IF ELSE
                
                Divider()
            }//: VSTACK
            
        } label: {
            GroupBoxLabelView(labelText: "Interface Settings", labelImage: "paintpalette.fill")
        }//: GROUPBOX
        // MARK: - TASK
        .task {
            let currentTagBadgeSetting = await dataController.tagBadgeCountFor
            if currentTagBadgeSetting != tagCounterType {
                tagCounterType = currentTagBadgeSetting
            }//: IF
        }//: TASK
        // MARK: - ON CHANGE
        .onChange(of: tagCounterType) { newType in
            dataController.setTagBadgeCount(to: newType)
        }//: ON CHANGE
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    GeneralUISettingsView()
}

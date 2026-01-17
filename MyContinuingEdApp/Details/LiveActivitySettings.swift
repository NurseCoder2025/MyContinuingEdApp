//
//  ActivityTypeAndFormatView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/29/25.
//

// Purpose: To show the UI controls for CeActivity properties related
// to live CE activities such as conferences, webinars, simulations,
// etc.  Properties like starting time and registration-related data
// are not applicable to non-live activites, so keeping them bundled in
// this sub-view.

import CoreData
import SwiftUI

/// Subview of ActivityBasicInfoView that contains UI controls for properties that pertain only
/// to CE activities considered to be "live activities".
///
/// Control of this view is determined by the CeActivity's isLiveActivity computed property value.
/// When true, this view will be shown in ActivityBasicInfoView.
struct LiveActivitySettings: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: Activity Format
            // ONLY 2 format types, so using a segmented style to save screen
            // space: in-person & virtual
            Section("Activity Format") {
                Picker("Format", selection: $activity.ceActivityFormat) {
                    ForEach(ActivityFormat.allFormats) {format in
                       Text(format.formatName)
                            .tag(format.formatName)
                    }//: LOOP
                    
                }//: PICKER
                .pickerStyle(.segmented)
            }//: SECTION
            
            // MARK: Start & Ending Times
            DisclosureGroup("Starting & Ending Times") {
                    VStack(spacing: 10) {
                        DatePicker(
                            "Starts",
                            selection: $activity.ceStartTime, displayedComponents: [.date, .hourAndMinute]
                        )//: DATE PICKER
                        
                        Toggle(isOn: $activity.startReminderYN) {
                            Text("Remind Me?")
                        }//: TOGGLE
                    }//: VSTACK
                    
                    DatePicker(
                        "Ends",
                        selection: $activity.ceEndTime, displayedComponents: [.date, .hourAndMinute]
                    )//: DATE PICKER
            }//: DISCLOSURE GROUP
            
           ActivityRegistrationSectionView(activity: activity)
    
        }//: GROUP
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    LiveActivitySettings(activity: .example)
}

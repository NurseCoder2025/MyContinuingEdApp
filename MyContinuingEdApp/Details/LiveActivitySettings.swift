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
                            "Starts On",
                            selection: $activity.ceStartTime, displayedComponents: [.date, .hourAndMinute]
                        )//: DATE PICKER
                        
                        Toggle(isOn: $activity.startReminderYN) {
                            Text("Remind Me?")
                        }//: TOGGLE
                    }//: VSTACK
                    
                    DatePicker(
                        "Ends On",
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

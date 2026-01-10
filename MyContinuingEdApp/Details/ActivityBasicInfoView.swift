//
//  ActivityViewHeader.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: Refactor ActivityView code so as to make it more maintanable and easier
// to read

import SwiftUI

struct ActivityBasicInfoView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // MARK: - CLOSURES
    // Adding this closure so as to pass up the sheet presentation
    // to the parent view (ActivityView) for better coordination
    var showACS: () -> Void
    
    // MARK: - COMPUTED PROPERTIES
    // Property that returns a joined String of all Credential names
    // assigned to an activity
    var assignedCredentials: String {
        let sortedCreds = activity.activityCredentials.sorted()
        let credString = sortedCreds.map {$0.credentialName}.joined(separator: ",")
        
        return credString
    }
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: Activity Title
            Section("Activity Name & Status") {
                TextField(
                    "Title:",
                    text: $activity.ceTitle,
                    prompt: Text("Enter the activity name here"),
                    axis: .vertical
                )
                .font(.title)
                
                Group {
                    VStack(alignment: .leading) {
                        // MARK: Modified Date
                        Text("**Modified:** \(activity.ceActivityModifiedDate.formatted(date: .long, time: .shortened))")
                            .foregroundStyle(.secondary)
                        
                        // MARK: Expiration status of activity
                        Text("**Expiration Status:** \(activity.expirationStatus.rawValue)")
                            .foregroundStyle(.secondary)
                    }//: VSTACK
                }//: GROUP
                .font(.caption)
                .multilineTextAlignment(.leading)
                
            }//: SECTION (title)
            
            // MARK: Start & Ending Times
            DisclosureGroup("Starting & Ending Times") {
                Section("Activity Date(s)") {
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
                    
                }//: SECTION
            }//: DISCLOSURE GROUP
            
            // MARK: Credentials
            Section("Activity For Credential(s)...") {
                    // Credential(s) to which activity is assigned to
                    if activity.activityCredentials.isNotEmpty {
                        Text("Assigned Credential(s): \(assignedCredentials)")
                    }
                    
                    // Show Credential Selection Sheet button
                    Button {
                        showACS()
                    } label: {
                        if activity.activityCredentials.isEmpty {
                            Label("Assign Credential", systemImage: "wallet.pass.fill")
                        } else {
                            Label("Manage Credential Assignments", systemImage: "list.bullet.clipboard.fill")
                        }
                    }//: BUTTON
                } //: SECTION (credential assignments)
            
                // MARK: Description & Tags
                Section("Description & Assigned Tags") {
                    VStack {
                        LeftAlignedTextView(text: "Activity Description:")
                            .font(.headline)
                            .bold()
                        TextField("Description:", text: $activity.ceDescription, prompt: Text("Enter a description of the activity"), axis: .vertical)
                            .keyboardType(.default)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2))
                            )
                    }//: VSTACK
                
                VStack {
                    Text("Assign custom tags to this activity:")
                    TagMenuView(activity: activity)
                }//: VSTACK
                
            }//: SECTION
        }//: GROUP
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityBasicInfoView(activity: .example, showACS: {})
}

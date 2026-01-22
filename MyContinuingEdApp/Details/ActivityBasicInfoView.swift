//
//  ActivityViewHeader.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: Refactor ActivityView code so as to make it more maintanable and easier
// to read

import CoreData
import SwiftUI

/// Subview of ActivityView that displays UI controls for a variety of properties that store essential information
/// about a CE activity (though all are optional).
/// - Parameters:
///     - activity: CeActivity object that is to be viewed/edited
///
/// - Closures: showACS() - assigned to the "Manage Credential Assingments" button for passing up
/// functionality to the parent view for displaying the CredentialManagementSheet.
/// - Computed Properities:
///     - assignedCredentials: returns a String of all Credential objects assigned to this activity (name value
///     only).
///
/// - CoreData Fetches:  allActivityTypes & allCredentials
/// - SubViews Called:
///     - WebsiteEntryView
///     - LiveActivitySettings (display is controlled by the activity's isLiveActivity computed property)
struct ActivityBasicInfoView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // Properties for storing values for various activity fields
    @State private var selectedActivityType: ActivityType?
    
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
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.typeName)]) var allActivityTypes: FetchedResults<ActivityType>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: Activity Title + Status
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
                        if activity.expirationStatus != .liveActivity {
                            Text("**Expiration Status:** \(activity.expirationStatus.rawValue)")
                                .foregroundStyle(.secondary)
                        }//: IF
                        
                    }//: VSTACK
                }//: GROUP
                .font(.caption)
                .multilineTextAlignment(.leading)
                
                // MARK: TAGS
                VStack {
                    Text("Assign custom tags to this activity:")
                    TagMenuView(activity: activity)
                }//: VSTACK
                
            }//: SECTION (title)
            
            // MARK: Activity Website
            Section("Activity Website"){
                WebSiteEntryView(
                    propertyURLString: $activity.ceInfoWebsiteURL,
                    textEntryLabel: "Website Address",
                    textEntryPrompt: "If the activity has a website, enter it here",
                    linkLabel: "Activity's Website"
                )
            }//: SECTION
            
            // MARK: Activity Type
            Section("Activity Type") {
                Picker("Type:", selection: $selectedActivityType) {
                    ForEach(allActivityTypes) { type in
                        Text(type.activityTypeName)
                            .tag(type as ActivityType?)
                    }//: LOOP
                    
                }//: PICKER
                .onChange(of: selectedActivityType) { newType in
                    activity.type = newType
                }//: ON CHANGE
            }//: SECTION
            
            if activity.isLiveActivity {
                LiveActivitySettings(activity: activity)
            }//: IF
            
            // MARK: Credentials
            Section("Activity For Credential(s)...") {
                    // Credential(s) to which activity is assigned to
                    if activity.activityCredentials.isNotEmpty {
                        Text("Assigned Credential(s): \(assignedCredentials)")
                    }
                    
                    // Show Credential Selection Sheet button
                if allCredentials.count > 1 {
                    Button {
                        showACS()
                    } label: {
                        if activity.activityCredentials.isEmpty {
                            Label("Assign Credential", systemImage: "wallet.pass.fill")
                        } else {
                            Label("Manage Credential Assignments", systemImage: "list.bullet.clipboard.fill")
                        }
                    }//: BUTTON
                }//: IF
                
            } //: SECTION (credential assignments)
            
            // MARK: Description
            Section("Description") {
                VStack {
                    LeftAlignedTextView(text: "Activity Description:")
                        .font(.headline)
                        .bold()
                    TextField("Description:", text: $activity.ceDescription, prompt: Text("Enter a description of the activity"), axis: .vertical)
                        .keyboardType(.default)
                        .frame(minHeight: 150, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2))
                        )
                }//: VSTACK
            
        }//: SECTION
        }//: GROUP
         // MARK: - ON APPEAR
         .onAppear {
             selectedActivityType = activity.type
         }//: ON APPEAR
        
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityBasicInfoView(activity: .example, showACS: {})
}

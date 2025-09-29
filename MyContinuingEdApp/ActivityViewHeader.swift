//
//  ActivityViewHeader.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: Refactor ActivityView code so as to make it more maintanable and easier
// to read

import SwiftUI

struct ActivityViewHeader: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // Bindings to parent view (ActivityView)
    @State private var showACSelectionSheet: Bool = false
    
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
            Section {
                VStack(alignment: .leading) {
                    // MARK: Activity Title
                    TextField(
                        "Title:",
                        text: $activity.ceTitle,
                        prompt: Text("Enter the activity name here"),
                        axis: .vertical
                    )
                        .font(.title)
                    
                    // Credential(s) to which activity is assigned to
                    if activity.activityCredentials.isNotEmpty {
                        Text("Assigned Credential(s): \(assignedCredentials)")
                    }
                    
                    // MARK: Show Credential Selection Sheet button
                    Button {
                        showACSelectionSheet = true
                    } label: {
                        if activity.activityCredentials.isEmpty {
                            Label("Assign Credential", systemImage: "wallet.pass.fill")
                        } else {
                            Label("Manage Credential Assignments", systemImage: "list.bullet.clipboard.fill")
                        }
                    }
                    
                    // MARK: Modified Date
                    Text("**Modified:** \(activity.ceActivityModifiedDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)
                    
                    // MARK: Expiration status of activity
                    Text("**Expiration Status:** \(activity.expirationStatus.rawValue)")
                        .foregroundStyle(.secondary)
                } //: VSTACK (title and modification date)
                
                // MARK: User's rating of the activity
                Picker("My Rating:", selection: $activity.evalRating) {
                    Text(ActivityRating.terrible.rawValue).tag(Int16(0))
                    Text(ActivityRating.poor.rawValue).tag(Int16(1))
                    Text(ActivityRating.soSo.rawValue).tag(Int16(2))
                    Text(ActivityRating.interesting.rawValue).tag(Int16(3))
                    Text(ActivityRating.lovedIt.rawValue).tag(Int16(4))
                }
                
            }//: SECTION
        }//: GROUP
        // MARK: - SHEETS
        // Credential(s) selection
        .sheet(isPresented: $showACSelectionSheet) {
            Activity_CredentialSelectionSheet(activity: activity)
        }//: SHEET (activity-credential selection)
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityViewHeader(activity: .example)
}

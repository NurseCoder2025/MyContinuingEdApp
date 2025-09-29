//
//  ActivityCompletionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/29/25.
//

// Purpose: To display all of the UI controls for CeActivity properties that are related to
// the completion of an activity

import SwiftUI

struct ActivityCompletionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: Activity Completion
            Section("Activity Completion") {
                Toggle("Activity Completed?", isOn: $activity.activityCompleted)
                if activity.activityCompleted {
                    DatePicker("Date Completed", selection: Binding(
                        get: {activity.dateCompleted ?? Date.now},
                        set: {activity.dateCompleted = $0}),
                    displayedComponents: [.date])
                    
                    if !activity.isDeleted, let reflection = activity.reflection {
                        NavigationLink {
                            ActivityReflectionView(activity: activity, reflection: reflection)
                        } label: {
                            Text("Activity reflections...")
                                .backgroundStyle(.yellow)
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        } //: NAV LINK
                        
                    }//: IF LET
                    
                } // IF activity completed...
            }//: SECTION (Activity Completion)
            // MARK: - ON CHANGE
            // MARK: Activity Completed? change
            .onChange(of: activity.activityCompleted) { _ in
                if activity.reflection == nil {
                    let newReflection = dataController.createNewActivityReflection()
                    activity.reflection = newReflection
                } //: IF
            } //: ON CHANGE
            
            // MARK: Date Completion change
            .onChange(of: activity.dateCompleted) { _ in
                dataController.assignActivitiesToRenewalPeriod()
            }
            
        }//: GROUP
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ActivityCompletionView(activity: .example)
}

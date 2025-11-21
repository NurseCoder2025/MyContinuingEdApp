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
    @EnvironmentObject var settings: CeAppSettings
    @ObservedObject var activity: CeActivity
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        settings.settings.appPurchaseStatus
    }
    
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
                    
                    if paidStatus == .free {
                        PaidFeaturePromoView(
                            featureIcon: "pencil.and.scribble",
                            featureItem: "Activity Reflection",
                            featureUpgradeLevel: .basicAndPro
                        )
                    } else {
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
                    }//: IF ELSE
                    
                } // IF activity completed...
            }//: SECTION (Activity Completion)
            // MARK: - ON CHANGE
            // MARK: Activity Completed? change
            .onChange(of: activity.activityCompleted) { _ in
                if paidStatus != .free {
                    if activity.reflection == nil {
                        let newReflection = dataController.createNewActivityReflection()
                        activity.reflection = newReflection
                    } //: IF
                }//: IF
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
        .environmentObject(CeAppSettings())
        .environmentObject(DataController(inMemory: true))
}

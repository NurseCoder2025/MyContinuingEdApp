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
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return .proSubscription
        case PurchaseStatus.basicUnlock.id:
            return .basicUnlock
        default:
            return .free
        }
    }//: paidStatus
    
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
                    
                    // MARK: User's rating of the activity
                    Picker("My Rating:", selection: $activity.evalRating) {
                        Text(ActivityRating.terrible.rawValue).tag(Int16(0))
                        Text(ActivityRating.poor.rawValue).tag(Int16(1))
                        Text(ActivityRating.soSo.rawValue).tag(Int16(2))
                        Text(ActivityRating.interesting.rawValue).tag(Int16(3))
                        Text(ActivityRating.lovedIt.rawValue).tag(Int16(4))

                    }//: PICKER
                    
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
                                Text("Reflect on the Activity")
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
        .environmentObject(DataController(inMemory: true))
}

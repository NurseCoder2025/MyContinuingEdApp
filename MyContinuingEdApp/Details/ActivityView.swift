//
//  ActivityView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/18/25.
//

// Purpose: For the creation and editing of Continuing Education (CE) activity objects.

import SwiftUI

struct ActivityView: View {
    // MARK: - Properties
    @Environment(\.spotlightCentral) var spotlightCentral
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Form {
            // MARK: Basic info
            // (name, credential assignment, description, tags)
            ActivityBasicInfoView(activity: activity)
            
            // MARK:  Activity Type & Format
            ActivityTypeAndFormatView(activity: activity)
            
            // MARK: Expiration Info
            ActivityExpirationDetailsView(activity: activity)
            
            // MARK: Hours & Cost
            ActivityHoursAndCostView(activity: activity)
            
            // MARK: CE Hours & Designation Info
            ActivityCEDetailsView(activity: activity)
            
            // MARK: Activity Completion
            ActivityCompletionView(activity: activity)
            
            // MARK: Certificate Image section
            ActivityCertificateImageView(activity: activity)
            
        } //: FORM
        
        // MARK: - DISABLED
        // Stays with ActivityView
        .disabled(activity.isDeleted)
        
        
        // MARK: - ON RECEIVE
        // Stays with ActivityView
        .onReceive(activity.objectWillChange) { _ in
            if #available(iOS 17, *) {
                dataController.queueSave()
            } else {
                dataController.queueSave()
                spotlightCentral?.updateCeActivityInDefaultIndex(activity)
            }
        
        } //: onReceive
        .onSubmit {
            if #available(iOS 17, *) {
                dataController.save()
            } else {
                dataController.save()
                spotlightCentral?.updateCeActivityInDefaultIndex(activity)
            }
            
        }//: ON SUBMIT
    }//: BODY
    

}//: STRUCT

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = DataController(inMemory: true)
        ActivityView(activity: .example)
            .environmentObject(controller)
    }
}




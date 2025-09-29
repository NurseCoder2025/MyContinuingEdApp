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
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    
    // MARK: - BODY
    var body: some View {
        Form {
            // MARK: HEADER section
            ActivityViewHeader(activity: activity)
            
            // MARK: Tag Menu
            TagMenuView(activity: activity)
            
            // MARK: Description & Expiration
            ActivityDescriptionSectionView(activity: activity)
            
            // MARK: Hours & Cost
            ActivityHoursAndCostView(activity: activity)
            
            // MARK: CE DETAILS
            ActivityCEDetailsView(activity: activity)
            
            // MARK:  Activity Type & Format
            ActivityTypeAndFormatView(activity: activity)
            
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
            dataController.queueSave()
        } //: onReceive
        
    }//: BODY
    
}//: STRUCT

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = DataController(inMemory: true)
        ActivityView(activity: .example)
            .environmentObject(controller)
            .environment(\.managedObjectContext, controller.container.viewContext)
    }
}




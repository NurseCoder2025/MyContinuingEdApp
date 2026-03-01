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
    @Environment(\.certificateBrain) var certificateBrain
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    @State private var showACSelectionSheet: Bool = false
    @State private var showCeDesignationSheet: Bool = false
    @State private var showSpecialCECatAssignmentSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        Form {
            // MARK: Basic info
            // (name, credential assignment, description, tags)
            ActivityBasicInfoView(activity: activity) {
                showACSelectionSheet = true
            }
            
            // MARK: Expiration Info
            if !activity.isLiveActivity {
                ActivityExpirationDetailsView(activity: activity)
            }//: IF
            
            // MARK: Hours & Cost
            ActivityHoursAndCostView(activity: activity)
            
            // MARK: CE Hours & Designation Info
            ActivityCEDetailsView(
                activity: activity,
                showCEDesignationSheet: {
                    showCeDesignationSheet = true
                },
                showSpecialCatSheet: {
                    showSpecialCECatAssignmentSheet = true
                }
            )
            
            // MARK: Activity Completion
            ActivityCompletionView(activity: activity)
            
            // MARK: Certificate Image section
            if let certBrain = certificateBrain {
                ActivityCertificateImageView(
                    dataController: dataController,
                    certificateBrain: certBrain,
                    activity: activity
                )
            }
        } //: FORM
        // MARK: - SHEETS
        // Credential(s) selection
        .sheet(isPresented: $showACSelectionSheet) {
            Activity_CredentialSelectionSheet(activity: activity)
        }//: SHEET (activity-credential selection)
        
        // CeDesgination selection (i.e. CME, legal CE, etc.)
        .sheet(isPresented: $showCeDesignationSheet) {
                CeDesignationSelectionSheet(activity: activity)
        }//: SHEET (CE Designation)
        
        // CE Category selection
        .sheet(isPresented: $showSpecialCECatAssignmentSheet) {
            SpecialCECatsManagementSheet(dataController: dataController, activity: activity)
        }//: SHEET (SpecialCECatASsignmentManagementSheet)
        
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




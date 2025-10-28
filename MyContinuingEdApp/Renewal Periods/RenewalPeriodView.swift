//
//  RenewalPeriodView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import CoreData
import SwiftUI

// Purpose: This view is for creating or editing existing RenewalPeriod objects.
// ⚠️ At least one Credential object MUST be created
// and saved in persistent storage in order for renewal periods to be created (and useful).

struct RenewalPeriodView: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    // Credential property that the renewal is assigned to
    let renewalCredential: Credential
    // Optional property used for editing a selected RenewalPeriod by the user
    let renewalPeriod: RenewalPeriod?
    // Renewal period properties
    @State private var periodStart: Date = Date.renewalStartDate
    @State private var periodEnd: Date = Date.renewalEndDate
    @State private var reinstatingYN: Bool = false
    @State private var reinstateHours: Double = 30.0
    @State private var lateFeeDate: Date = Date.renewalLateFeeStartDate
    @State private var lateFeeAmount: Double = 50.0
    // MARK: - CORE DATA Fetches
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    // MARK: - BODY
    var body: some View {
        ScrollView {
            VStack {
                // MARK: - Sheet Title
                RenewalPeriodSheetTitleView(renewalPeriod: renewalPeriod)
                
                // MARK: - Credential Selection
                VStack{
                        RenewalTopEditingView(
                            credential: renewalCredential,
                            reinstatingYN: $reinstatingYN,
                            reinstateHours: $reinstateHours
                        )
                        
                        RenewalPeriodDatesView(
                            lateFeeDate: $lateFeeDate,
                            lateFeeAmount: $lateFeeAmount,
                            periodStart: $periodStart,
                            periodEnd: $periodEnd
                        )
                        
                        // MARK: SAVE Button
                        Button {
                            saveRenewal()
                            dismiss()
                        } label: {
                            Text("Save & Dismiss")
                        }
                        .buttonStyle(.borderedProminent)
                        
                    } //: VSTACK
                    
            } //: SCROLLVIEW
            
            // MARK: - ON APPEAR
            // Since this view is used for both creating and editing renewal period
            // objects, it is important to assign the start and end date properties
            // for the renewal period object to the local properties upon load.
            // Otherwise, the user will only see the default dates and could get confused.
            .onAppear {
                periodStart = renewalPeriod?.periodStart ?? Date.renewalStartDate
                periodEnd = renewalPeriod?.periodEnd ?? Date.renewalEndDate
            }
            
        }//: VSTACK
            
    } //: BODY
    
    // MARK: - Functions
    /// Maps Renewal Period properties that are user-editable in controls to their corresponding property in the object.
    /// - Parameter renewal: Existing or new renewal object being passed in
    func mapProperties(for renewal: RenewalPeriod) {
        renewal.periodStart = periodStart
        renewal.periodEnd = periodEnd
        renewal.credential = renewalCredential
        renewal.reinstateCredential = reinstatingYN
        renewal.reinstatementHours = reinstateHours
        renewal.lateFeeStartDate = lateFeeDate
        renewal.lateFeeAmount = lateFeeAmount
    }
    
    
    /// Maps local properties to either the renewal period object that was passed in OR
    /// to a newly created RenewalPeriod object then saves context changes.
    ///
    /// After saving the method then calls the assignActivitiesToRenewalPeriod data controller method
    /// to automatically assign existing CeActivity objects to the object IF matching criteria are met.
    /// For an activity to be assigned to a renewal period, it must meet the following criteria:
    /// 1. Marked as completed by the user
    /// 2. The completion date falls between the renewal period's start and end dates
    func saveRenewal() {
        if let existingRenewal = renewalPeriod {
            mapProperties(for: existingRenewal)
        } else {
            let newRenewal = dataController.createRenewalPeriod()
            mapProperties(for: newRenewal)
        }
        
        dataController.save()
        dataController.assignActivitiesToRenewalPeriod()
    }
}


// MARK: - Preview

/// Enables the preview for this view for development and testing purposes.
struct RenewalPeriodView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create and save a Credential in the preview context
        let credential = Credential(context: context)
        credential.name = "Example Credential"
        try? context.save()
        
        // Create a RenewalPeriod assigned to the credential
        let renewalPeriod = RenewalPeriod(context: context)
        renewalPeriod.periodStart = Date.renewalStartDate
        renewalPeriod.periodEnd = Date.renewalEndDate
        renewalPeriod.credential = credential
        
        try? context.save()
        
        return RenewalPeriodView(renewalCredential: credential, renewalPeriod: renewalPeriod)
            .environmentObject(controller)
            .environment(\.managedObjectContext, context)
    }
}

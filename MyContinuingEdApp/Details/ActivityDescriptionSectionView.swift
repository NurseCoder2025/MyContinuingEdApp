//
//  ActivityDescriptionSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: To create the UI controls for the CE description and expriation parts
// of the parent view (ActivityView) for better code management and organization.

import SwiftUI

struct ActivityDescriptionSectionView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section("Description & Activity Expiration") {
                TextField("Description:", text: $activity.ceDescription, prompt: Text("Enter a description of the activity"), axis: .vertical)
                    .keyboardType(.default)
                
                // MARK: Expiration Toggle
                Toggle("Expires?", isOn: $activity.activityExpires)
                    
                
                if activity.activityExpires {
                    Toggle("Remind Me?", isOn: $activity.expirationReminderYN)
                    
                    DatePicker("Expires On", selection: Binding(
                        get: { activity.expirationDate ?? Date.now },
                        set: { activity.expirationDate = $0 }),
                        displayedComponents: [.date])
                    
                    // MARK: ON CHANGE OF
                        .onChange(of: activity.expirationDate) { _ in
                            updateActivityStatus(status: activity.expirationStatus)
                        } //: ON CHANGE
                    
                } //: IF expires...
                
            } //: Description Subsection
        }//: GROUP
        .animation(.default, value: activity.activityExpires)
        // MARK: - ON APPEAR
        .onAppear {
            updateActivityStatus(status: activity.expirationStatus)
        }
    }//: BODY
    
    // MARK: - FUNCTIONS
    /// The updateActivityStatus function exists to enable filtering functionality in the DataController. -->
    /// Adding this function in order to automatically assign the computed ExpirationType value
    /// from the CEActivity-Core DataHelper file (see bottom extension) to the direct property in Core Data.
    /// Need to use this in order to properly filter activities by expiration status (type) in the DataController.
    func updateActivityStatus(status: ExpirationType) {
        activity.currentStatus = status.rawValue
    }
    
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ActivityDescriptionSectionView(activity: .example)
}

//
//  RenewalPeriodView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import CoreData
import SwiftUI

// This view is for creating or editing existing RenewalPeriod objects.
// At least one Credential object MUST be created
// and saved in persistent storage in order for renewal periods to be created (and useful).

struct RenewalPeriodView: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Optional property used for editing a selected RenewalPeriod by the user
    let renewalPeriod: RenewalPeriod?
    
    // Renewal period properties
    @State private var periodStart: Date = Date.renewalStartDate
    @State private var periodEnd: Date = Date.renewalEndDate
    
    // Credential property that the renewal is assigned to
    @State private var renewalCredential: Credential?
    
    // For showing the CredentialSheet to add a NEW credential object
    @State private var showCredentialSheet: Bool = false
    
    // MARK: - CORE DATA Fetches
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        // MARK: - Sheet Title
            VStack {
                if let existingRenewal = renewalPeriod {
                    if existingRenewal.renewalPeriodName != "" {
                        Text(existingRenewal.renewalPeriodName)
                            .font(.largeTitle)
                    } else {
                        Text("Add New Renewal Period")
                            .font(.largeTitle)
                    }
                }
            }//: VSTACK
            .padding(.bottom, 20)
                
        
            
        VStack {
            // MARK: - Credential Selection
            if allCredentials.isEmpty {
                NoCredentialsView()
            } else {
                Picker("Select Credential", selection: $renewalCredential) {
                    ForEach(allCredentials) { credential in
                        Text(credential.credentialName).tag(credential)
                    }//: LOOP
                }//: PICKER
                
                Button {
                    // TODO: Replace CredentialSheet with CredentialListView
                    showCredentialSheet = true
                } label: {
                    Label("Add Credential", systemImage: "square.and.at.rectangle.fill")
                }
            }
                
                // MARK: - Renewal START
                Group {
                    VStack{
                        Text("Enter the date the renewal period begins:")
                            .font(.headline)
                        Text("If you don't know the exact date, enter January 1st of the starting year")
                            .font(.caption)
                        DatePicker(
                            "Starting Date",
                            selection: $periodStart,
                            displayedComponents: .date
                        )
                        .padding([.leading, .trailing], 35)
                    }//: VSTACK
                    .padding(.bottom, 10)
                }//: GROUP
                
                Divider()
                
                // MARK: - Renewal ENDS
                Group {
                    VStack {
                        Text("Enter the date your renewal period ends:")
                            .font(.headline)
                        Text("If you don't know the exact date, enter the last day of the month in which the renewal ends of the respective year.")
                            .font(.caption)
                            .padding([.leading, .trailing], 30)
                        DatePicker(
                            "Ending Date",
                            selection: $periodEnd,
                            displayedComponents: .date
                        )
                        .padding([.leading, .trailing], 35)
                        .padding(.bottom, 20)
                    }//: VSTACK
                    .padding(.top, 10)
                } //: GROUP
                
                // MARK: - SAVE Button
                Button {
                    saveRenewal()
                    dismiss()
                } label: {
                    Text("Save & Dismiss")
                }
                .buttonStyle(.borderedProminent)
                
                
            }//: VSTACK
            .onAppear {
                periodStart = renewalPeriod?.periodStart ?? Date.renewalStartDate
                periodEnd = renewalPeriod?.periodEnd ?? Date.renewalEndDate
            }
            
            
            
    } //: BODY
    
    // MARK: - Functions
    /// Maps Renewal Period properties that are user-editable in controls to their corresponding property in the object.
    /// - Parameter renewal: Existing or new renewal object being passed in
    func mapProperties(for renewal: RenewalPeriod) {
        renewal.periodStart = periodStart
        renewal.periodEnd = periodEnd
        renewal.credential = renewalCredential
    }
    
    func saveRenewal() {
        if let existingRenewal = renewalPeriod {
            mapProperties(for: existingRenewal)
        } else {
            let context = dataController.container.viewContext
            let newRenewal = RenewalPeriod(context: context)
            
            mapProperties(for: newRenewal)
            
        }
        
        dataController.save()
        dataController.assignActivitiesToRenewalPeriod()
    }
    
}


// MARK: - Preview
struct RenewalPeriodView_Previews: PreviewProvider {
    static var previews: some View {
        RenewalPeriodView(renewalPeriod: .example)
    }
}

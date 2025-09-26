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
                VStack {
                    if let existingRenewal = renewalPeriod {
                        if existingRenewal.renewalPeriodName != "" {
                            Text(existingRenewal.renewalPeriodName)
                                .font(.largeTitle)
                        }
                    } else {
                        Text("Add New Renewal Period")
                            .font(.title)
                            .padding()
                    }
                }//: VSTACK
                .padding(.bottom, 20)
                
               
                    // MARK: - Credential Selection
                    // Check to see if any credentials have been entered yet and if not,
                    // only show the NoCredentialsVie
                    if allCredentials.isEmpty {
                        NoCredentialsView()
                    } else {
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
                    }//: IF-ELSE
                    
            } //: SCROLLVIEW
            
            // MARK: - ON APPEAR
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
        RenewalPeriodView(renewalCredential: .example, renewalPeriod: .example)
    }
}

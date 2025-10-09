//
//  CredentialNextExpirationSectionView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//


// Purpose: To display the UI elements that display the number of days until the credential needs
// to be renewed (if renewal periods have been entered).  If no renewal periods have been entered,
// or if the most recent renewal in the app is outdated, then this section will prompt the user
// to either create a renewal period for the credential or add a new one that reflects the
// current renewal period.

// Note: This view will only be shown if an existing Credential object exists

import CoreData
import SwiftUI

struct CredentialNextExpirationSectionView: View {
    // MARK: - PROPERTIES
    
    // Needed properties
    // - credential (let constant from parent)
    // - renewalLength (Double as read-only)
    // - renewalsSorted (Core Data fetch request)
    // - showRenewalPeriodView (Bool) - for showing the RenewalPeriodView sheet
    
    let credential: Credential?
    let renewalLength: Double

    // Property to display RenewalPeriod sheet
    @State private var showRenewalPeriodView: Bool = false
    
    
    // MARK: - CORE DATA FETCH REQUESTS
    // This property will be used to determine the most recent (current) renewal
    // period for calculating the next expiration date of the credential
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodEnd, order: .reverse)]) var renewalsSorted: FetchedResults<RenewalPeriod>
    
    // MARK: - BODY
    var body: some View {
        // Note: This view will only be shown if an existing Credential object exists since
        // this view displays a calculation result based on when the credential object
        // needs to be renewed next.
        Group {
            if credential != nil {
                Section("Next Expiration"){
                    if renewalLength <= 0.0 {
                        Text("Please enter the number of months the credential is valid before it expires.")
                            .foregroundStyle(.secondary)
                    } else {
                        if renewalsSorted.isEmpty {
                            Text("Please add a renewal period in order to calculate the next expiration date for this credential.")
                                .foregroundStyle(.secondary)
                            Button{
                                showRenewalPeriodView = true
                            } label: {
                                Label("Add Renewal", systemImage: "plus")
                            }
                        } else {
                            // If there is at least one value in the renewalsSorted
                            // fetch request, then calculate the next expiration date
                            // based on the first item in the array
                            let mostCurrentRenewal = renewalsSorted[0]
                            let minutesToRenew = mostCurrentRenewal.renewalPeriodEnd.timeIntervalSince(Date.now)
                            let daysToRenew = minutesToRenew / 86400
                            
                            // if the most recent renewal period happens to have
                            // an ending date prior to the current date
                            // (meaning no current renewal period has been entered yet) then
                            // alert the user and prompt him to add a new (current) period
                            if daysToRenew <= 0 {
                                Text("The latest renewal period entered has ended./nPlease enter a new renewal period that includes today's date so that the time until the next expiration can be calculated.")
                                    .foregroundStyle(.secondary)
                                Button {
                                    showRenewalPeriodView = true
                                } label: {
                                    Text("Add new (current) renewal period")
                                }
                            } else {
                                VStack {
                                    Text(mostCurrentRenewal.renewalPeriodName)
                                    Text("\(NSNumber(value: daysToRenew), formatter: singleDecimalFormatter) days before the credential expires")
                                        .font(.title)
                                        .bold()
                                }//: VSTACK
                            }
                        }//: INNER IF-ELSE
                    } //: ELSE
                }//: SECTION
            }//: IF
        }//: GROUP
        // MARK: - SHEETS
        // Renewal Period sheet
        // Calling this sheet is ONLY for adding new RenewalPeriod objects
        .sheet(isPresented: $showRenewalPeriodView) {
            if let cred = credential {
                RenewalPeriodView(renewalCredential: cred, renewalPeriod: nil)
            } else {
                Text("Unable to create credential. Please close and save the credential being entered first, then try again.")
            }
        }//: SHEET
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CredentialNextExpirationSectionView(
        credential: .example,
        renewalLength: 24.0
    )
}

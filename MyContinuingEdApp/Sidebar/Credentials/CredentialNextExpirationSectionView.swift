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
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var credential: Credential

    // Property to display RenewalPeriod sheet
    @State private var showRenewalPeriodView: Bool = false
    
    
    // MARK: - COMPUTED PROPERTIES
    // This property will be used to determine the most recent (current) renewal
    // period for calculating the next expiration date of the credential
    var renewalsSorted: [RenewalPeriod] {
        // Fetch all RenewalPeriods that are connected to the credential
        let renewals = RenewalPeriod.fetchRequest()
        renewals.predicate = NSPredicate(format: "credential == %@", credential)
        renewals.sortDescriptors = [NSSortDescriptor(key: "periodStart", ascending: false)]
        
        let container = dataController.container
        let fetchedRenewals: [RenewalPeriod] = (try? container.viewContext.fetch(renewals)) ?? []
        
        return fetchedRenewals
            
    }//: renewalsSorted
    
    // MARK: - BODY
    var body: some View {
        // Note: This view will only be shown if an existing Credential object exists since
        // this view displays a calculation result based on when the credential object
        // needs to be renewed next.
        Group {
            Section("Next Expiration"){
                if credential.renewalPeriodLength <= 0.0 {
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
                        // Calculate the number of days until the credential expires
                        let daysToRenew = calcTimeUntilNextExpiration(renewals: renewalsSorted).days
                        let renewalName = calcTimeUntilNextExpiration(renewals: renewalsSorted).name
                        
                        // If the daysToRenew is -1, then today's date doesn't fall within any of the
                        // renewal periods that have been entered thus far, so prompt the user to create
                        // a new renewal period that includes today's date
                        if daysToRenew < 0 {
                            Text("There are currently no renewal periods which include today's date.\nPlease add a new renewal period that includes today's date so that the time until the next expiration can be calculated.")
                                .foregroundStyle(.secondary)
                            Button {
                                showRenewalPeriodView = true
                            } label: {
                                Text("Add new (current) renewal period")
                            }
                        } else {
                            VStack {
                                Text(renewalName)
                                Text("^[\(NSNumber(value: daysToRenew), formatter: wholeNumFormatter) day before the credential expires] (inflect: true)")
                                    .font(.title)
                                    .bold()
                            }//: VSTACK
                            .accessibilityElement()
                            .accessibilityLabel("Days Until Credential Expires")
                            .accessibilityHint("^[\(NSNumber(value: daysToRenew)) day] (inflect: true)")
                        }
                    }//: INNER IF-ELSE
                } //: ELSE
            }//: SECTION
            
        }//: GROUP
        // MARK: - SHEETS
        // Renewal Period sheet
        // Calling this sheet is ONLY for adding new RenewalPeriod objects
        .sheet(isPresented: $showRenewalPeriodView) {
                RenewalPeriodView(renewalCredential: credential, renewalPeriod: nil)
        }//: SHEET
        
    }//: BODY
     // MARK: - FUNCTIONS
    /// Function for calculating the number of days between the current date and the end date for a given renewal period.  This funciton is
    /// intended to be used within the CredentialNextExpirationSectionView and only take the most recent renewal period object.
    /// - Parameter renewals: array of RenewalPeriod objects (should be the renewalsSorted computed property)
    /// - Returns: a tuple with the number of days until expiration (Int) and the name of the renewal period (String)
    func calcTimeUntilNextExpiration(renewals: [RenewalPeriod]) -> (days:Int, name:String) {
        // Return a -1 if no renewal periods currently exist (and nothing was passed in)
        guard renewals.isNotEmpty else {return (-1, "")}
        
        // Get today's date
        let todaysDate: Date = Date.now
        
        // Find the renewal period that today's date falls within
        let currentRenewalArray = renewals.filter {
            $0.renewalPeriodStart <= todaysDate && $0.renewalPeriodEnd >= todaysDate
        }
        
        // Convert the array to a single object (if it exists)
        guard let currentRenewal = currentRenewalArray.first else {return (-1, "")}
        
        // Calculate the number of days between today's date and the end date for the current renewal period
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: todaysDate, to: currentRenewal.renewalPeriodEnd).day ?? -1
        
        return (daysUntilExpiration, currentRenewal.renewalPeriodName)
        
     }//: FUNC
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CredentialNextExpirationSectionView(credential: .example)
}

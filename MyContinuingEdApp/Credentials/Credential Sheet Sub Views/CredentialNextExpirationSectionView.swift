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
    @EnvironmentObject var settings: CeAppSettings
    
    @ObservedObject var credential: Credential

    // Property to display RenewalPeriod sheet
    @State private var showRenewalPeriodView: Bool = false
    
    @State private var showUpgradeToPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus? = nil
    @State private var showFeaturesDetailsSheet: Bool = false
    
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
                        let daysToRenew = dataController.calcTimeUntilNextExpiration(renewals: renewalsSorted).days
                        let renewalName = dataController.calcTimeUntilNextExpiration(renewals: renewalsSorted).name
                        
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
                                    .font(.title2).bold()
                                HStack {
                                    Spacer()
                                    Text("^[\(NSNumber(value: daysToRenew), formatter: wholeNumFormatter) day before the credential expires](inflect: true)")
                                        .font(.title3)
                                    Spacer()
                                }//: HSTACK
                            }//: VSTACK
                            .accessibilityElement()
                            .accessibilityLabel("Days Until Credential Expires")
                            .accessibilityHint("^[\(NSNumber(value: daysToRenew)) day](inflect: true)")
                        }
                    }//: INNER IF-ELSE
                } //: ELSE
            }//: SECTION
            
        }//: GROUP
        // MARK: - SHEETS
        // Renewal Period sheet
        // Calling this sheet is ONLY for adding new RenewalPeriod objects
        .sheet(isPresented: $showRenewalPeriodView) {
            let renewalNumber = dataController.currentNumberOfRenewals
            let currentPurchaseLevel = settings.settings.appPurchaseStatus
            if currentPurchaseLevel != .free {
                RenewalPeriodView(renewalCredential: credential, renewalPeriod: nil)
            } else if currentPurchaseLevel == .free && renewalNumber < 1 {
                RenewalPeriodView(renewalCredential: credential, renewalPeriod: nil)
            } else {
                UpgradeToPaidSheet(
                    itemMaxReached: "renewals",
                    learnMore: { type in
                        selectedUpgradeOption = type
                        showFeaturesDetailsSheet = true
                    },
                    purchaseItem: { type in
                        selectedUpgradeOption = type
                    }
                )
            }//: IF ELSE
        }//: SHEET
        
        .sheet(isPresented: $showFeaturesDetailsSheet) {
            if let selectedOption = selectedUpgradeOption {
                FeaturesDetailsSheet(upgradeType: selectedOption)
            }
        }//: SHEET
        
    }//: BODY
    
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CredentialNextExpirationSectionView(credential: .example)
}

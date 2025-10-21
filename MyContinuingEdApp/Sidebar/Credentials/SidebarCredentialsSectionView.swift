//
//  SidebarCredentialsSectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//
//

// Purpose: To encapsulate UI controls & behavior related to the Credentials section of SidebarView
// This includes both the Credential section as well as the RenewalPeriod subsection as renewal periods
// have a many to one relationship with Credential.

import CoreData
import SwiftUI

struct SidebarCredentialsSectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // Deleting renewal periods
    @State private var showDeletingRenewalAlert: Bool = false
    @State private var renewalToDelete: RenewalPeriod?
    
   // Closure for editing a renewal period
    var onEditRenewal: (Credential, RenewalPeriod) -> Void
    
    // Closure for deleting a renewal period
    var onRenewalDelete: (RenewalPeriod) -> Void
    
    // Closure for adding a new renewal period
    var onAddRenewal: (Credential) -> Void
    
    // Credential for adding a new renewal period
    @State private var credForRenewal: Credential?
    
    
    // MARK: - COMPUTED PROPERTIES

    // Converting all fetched renewal periods to Filter objects
    var convertedRenewalFilters: [Filter] {
        renewals.map { renewal in
            Filter(
                name: renewal.renewalPeriodName,
                icon: "timer.square",
                renewalPeriod: renewal,
                credential: renewal.credential
            )
        }
    }//: convertedRenewalFilters
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // Retrieving all saved renewal periods
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodName)]) var renewals: FetchedResults<RenewalPeriod>
    
    // MARK: - BODY
    var body: some View {
            // IF NO credentials have yet been entered (or have been deleted)
            if allCredentials.isEmpty {
                Section("Add License, Certification, or Other Credential") {
                    NoCredentialsView()
                }//: SECTION
            } else {
               Group {
                ForEach(allCredentials) { credential in
                    // Creating a section for each renewal period for the credential
                    Section {
                        ForEach(convertedRenewalFilters.filter{$0.credential == credential}) { filter in
                            NavigationLink(value: filter) {
                                Label(filter.name, systemImage: "calendar.badge.clock")
                                    .badge(filter.renewalActivitiesCount)
                                    .contextMenu {
                                        // Edit Renewal Period
                                        Button {
                                            guard let renewal = filter.renewalPeriod, renewals.contains(renewal) else { return }
                                            guard let selectedCred = renewal.credential else {return}
                                            // Print statements work OK as of 10/15/25
                                            print("Renewal being edited: \(renewal.renewalPeriodName)")
                                            print("For credential: \(selectedCred.credentialName)")
                                            onEditRenewal(selectedCred, renewal)
                                        } label: {
                                            Label("Edit Renewal Period", systemImage: "pencil")
                                        }
                                        
                                        // Delete Renewal Period
                                        Button(role: .destructive) {
                                            renewalToDelete = filter.renewalPeriod
                                            if let deletingRenewal = renewalToDelete {
                                                onRenewalDelete(deletingRenewal)
                                            }
                                        } label: {
                                            Label("Delete Renewal Period", systemImage: "trash.fill")
                                        }
                                    }//: CONTEXT MENU
                                    .accessibilityElement()
                                    .accessibilityLabel("Renewal period: \(filter.name)")
                                    .accessibilityHint("^[\(filter.renewalActivitiesCount) CE activity](inflect: true)")
                                
                            }//: NAV LINK
                        }//: LOOP
                    } header: {
                        SidebarCredentialSectionHeader(
                            credential: credential,
                            addNewRenewal: { cred in
                                onAddRenewal(cred)
                            }//: ADD NEW RENEWAL
                        )
                    }//: SECTION w/ custom header
                }//: LOOP (credentials)
               
            }//: GROUP
            
            // MARK: - ON APPEAR
            .onAppear {
                renewalToDelete = nil
            }//: ON APPEAR
                
        }//: IF - ELSE
        
    }//: BODY
    // MARK: - FUNCTIONS
    
    
}//: STRUCT

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
    @StateObject private var viewModel: ViewModel
    
    // MARK: - CLOSURES
   // Closure for editing a renewal period
    var onEditRenewal: (Credential, RenewalPeriod) -> Void
    
    // Closure for deleting a renewal period
    var onRenewalDelete: (RenewalPeriod) -> Void
    
    // Closure for adding a new renewal period
    var onAddRenewal: (Credential) -> Void
    
    // Closure for creating a Credential object
    var addInitalCredential: () -> Void
   
    // MARK: - BODY
    var body: some View {
            // IF NO credentials have yet been entered (or have been deleted)
        if viewModel.allCredentials.isEmpty {
                Section("Add License, Certification, or Other Credential") {
                    NoCredentialsButtonView {
                        addInitalCredential()
                    }
                }//: SECTION
            } else {
               Group {
                   ForEach(viewModel.allCredentials) { credential in
                    // Creating a section for each renewal period for the credential
                    Section {
                        ForEach(viewModel.convertedRenewalFilters.filter{$0.credential == credential}) { filter in
                            NavigationLink(value: filter) {
                                Label(filter.name, systemImage: "calendar.badge.clock")
                                    .badge(filter.renewalActivitiesCount)
                                    .contextMenu {
                                        // MARK: Edit Renewal Period Button
                                        Button {
                                            guard let renewal = filter.renewalPeriod, viewModel.renewals.contains(renewal) else { return }
                                            guard let selectedCred = renewal.credential else {return}
                                            onEditRenewal(selectedCred, renewal)
                                        } label: {
                                            Label("Edit Renewal Period", systemImage: "pencil")
                                        }
                                        
                                        // MARK: Delete Renewal Period Button
                                        Button(role: .destructive) {
                                            viewModel.renewalToDelete = filter.renewalPeriod
                                            if let deletingRenewal = viewModel.renewalToDelete {
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
                            dataController: viewModel.dataController,
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
                viewModel.renewalToDelete = nil
            }//: ON APPEAR
                
        }//: IF - ELSE
        
    }//: BODY
    
    // MARK: - INIT
    init(
        dataController: DataController,
        onEditRenewal: @escaping (Credential, RenewalPeriod) -> Void,
        onAddRenewal: @escaping (Credential) -> Void,
        onRenewalDelete: @escaping (RenewalPeriod) -> Void,
        addInitialCredential: @escaping () -> Void
    ) {
        
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.onEditRenewal = onEditRenewal
        self.onAddRenewal = onAddRenewal
        self.onRenewalDelete = onRenewalDelete
        self.addInitalCredential = addInitialCredential
        
    }//: INIT

}//: STRUCT

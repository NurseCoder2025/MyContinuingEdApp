//
//  SidebarView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI
import UIKit


// The primary (initial) view when first launching the app. Provides different ways of filtering
// CE activities that have been entered: via 2 "smart" filters, user-created tags, and by
// credential-renewal cycle.

struct SidebarView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @AppStorage("firstRun") var firstRun: Bool = true
    @Environment(\.openURL) var openURL
    
    @StateObject private var viewModel: ViewModel
    @State private var showEnableRemindersAlert: Bool = false
    @State private var showRenewalProgressSheet: Bool = false
    @State private var showAddNewTagAlert: Bool = false
    @State private var showUpgradeToPaidSheet: Bool = false
    @State private var showFeaturesDetailsSheet: Bool = false
    
    // MARK: Smart filters
    let smartFilters: [Filter] = [.allActivities, .recentActivities]
    
    // MARK: - Computed Properties
    var paidStatus: PurchaseStatus {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return .proSubscription
        case PurchaseStatus.basicUnlock.id:
            return .basicUnlock
        default:
            return .free
        }
    }//: paidStatus
   
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            List(selection: $viewModel.dataController.selectedFilter) {
                // MARK: - SMART FILTERS SECTION
                Section("Smart Filters") {
                    ForEach(smartFilters, content: SidebarSmartFilterRow.init)
                } //: SECTION (smart filters)
                
                // MARK: - TAGS SECTION
                SidebarTagsSectionView(
                    dataController: viewModel.dataController,
                    onRenameTag: { filter in
                        viewModel.tagFilter = filter
                        viewModel.tagToRename = filter.tag
                        viewModel.newTagName = filter.name
                        viewModel.showRenamingAlert = true
                    },
                    onCreateNewTag: {
                        showAddNewTagAlert = true
                    }
                )
                // MARK: - CREDENTIALS SECTION
                SidebarCredentialsSectionView(
                    dataController: viewModel.dataController,
                    onEditRenewal: { cred, renewal in
                        viewModel.renewalSheetData = RenewalSheetData(credential: cred, renewal: renewal)
                    },
                    onAddRenewal: { cred in
                        viewModel.renewalSheetData = RenewalSheetData(credential: cred, renewal: nil)
                    },
                    onRenewalDelete: { renewal in
                        viewModel.renewalToDelete = renewal
                        viewModel.showDeleteRenewalWarning = true
                        if viewModel.showDeleteRenewalWarning {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }
                    },
                    addInitialCredential: {
                        let newCred = viewModel.dataController.createNewCredential()
                        viewModel.newlyCreatedCredential = newCred
                    },
                    showRenewalProgress: { renewal in
                        viewModel.selectedRenewalForProgressCheck = renewal
                        showRenewalProgressSheet = true
                        
                    }
                    
                )//: SidebarCredentialsSectionView
            } //: LIST
            
           
        }//: NAV STACK
            .navigationTitle("CE Filters")
            // MARK: - Toolbar
            .toolbar(content: SidebarViewTopToolbar.init)
        // MARK: - ON APPEAR
            .onAppear {
                // First time running of app only
                if firstRun == true {
                    dataController.showOnboardingScreen = true
                    firstRun = false
                    showEnableRemindersAlert = true
                }
                
                // Updating notifications
                Task { @MainActor in
                    await viewModel.dataController.updateAllReminders()
                }//: TASK
                
            }//: ON APPEAR
        // MARK: - Alerts
        .alert("Name New Tag", isPresented: $showAddNewTagAlert) {
            TextField("Tag Name", text: $viewModel.addedTagName)
            Button("OK", action: {
                do {
                    try viewModel.dataController.createTagWithName(viewModel.addedTagName)
                    viewModel.addedTagName = ""
                    
                } catch  {
                    viewModel.itemMaxedOut =  "tags"
                    showUpgradeToPaidSheet = true
                }
                
            })
            Button("Cancel", role: .cancel) {viewModel.addedTagName = ""}
        }//: ALERT
        
        // RENAMING TAG ALERT
            .alert("Rename Tag", isPresented: $viewModel.showRenamingAlert) {
                Button("OK", action: { viewModel.confirmTagRename() })
            Button("Cancel", role: .cancel) {}
                TextField("New tag name:", text: $viewModel.newTagName)
        } //: ALERT
        
        // Deleting renewal period alert
            .alert("Delete Renewal Period?", isPresented: $viewModel.showDeleteRenewalWarning) {
                Button("OK", action: {viewModel.deleteRenewalPeriod()})
            Button("Cancel", role: .cancel) {}
        } message:  {
            Text("Deleting the \(viewModel.renewalToDelete?.renewalPeriodName ?? "renewal period") will NOT delete any associated CE activities or credentials, but may impact renewal reminders and alerts. Are you sure you wish to delete it? ")
        }//: ALERT
        
        // Notifications disabled alert
        .alert("Enable Notifications",isPresented: $showEnableRemindersAlert) {
            if #available(iOS 26.0, *) {
                Button("OK", role: .confirm) {}
            } else {
                // Fallback on earlier versions
                Button("OK") {}
            }
            Button("Settings", action: showAppSettings)
        } message: {
            Text("Hello there! To help you stay on top of renewal deadlines and CE expirations, please ensure that notifications are enabled for this app.")
        }
        
        
        // MARK: - SHEETS
        .sheet(item: $viewModel.renewalSheetData) { data in
            let currentRenewalNum = viewModel.dataController.currentNumberOfRenewals
            
            if paidStatus != .free {
                RenewalPeriodView(renewalCredential: data.credential, renewalPeriod: data.renewal)
            } else if paidStatus == .free && currentRenewalNum < 1 {
                RenewalPeriodView(renewalCredential: data.credential, renewalPeriod: data.renewal)
            } else {
                UpgradeToPaidSheet(itemMaxReached: "renewals")//: UpgradeToPaidSheet
            }//: IF - ELSE
        }//: SHEET
        
        .sheet(item: $viewModel.newlyCreatedCredential) { _ in
            if let addedCred = viewModel.newlyCreatedCredential {
                CredentialSheet(credential: addedCred)
            }
        }//: SHEET
        
        .sheet(item: $viewModel.selectedRenewalForProgressCheck) { _ in
            if let selectedRenewal = viewModel.selectedRenewalForProgressCheck {
                RenewalProgressSheet(renewal: selectedRenewal)
            }
        }//: SHEET
        
        .sheet(isPresented: $showUpgradeToPaidSheet) {
            UpgradeToPaidSheet(itemMaxReached: viewModel.itemMaxedOut)
        }//: SHEET
        
        
    } //: BODY
    
    // MARK: - METHODS
    
    /// Method that opens the Settings app so that the user can adjust notification settings if needed
    func showAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(settingsURL)
    }
    
    
 // MARK: - INIT
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
        
} //: STRUCT

// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(dataController: .preview)
           
    }
}

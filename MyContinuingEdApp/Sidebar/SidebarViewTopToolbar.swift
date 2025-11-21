//
//  SidebarViewToolbar.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//


// Purpose: To encapsulate functionality for showing the awards and credential management sheets from the parent
// view (SidebarView)


import SwiftUI

struct SidebarViewTopToolbar: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var settings: CeAppSettings
    
    @State private var showAwardsSheet: Bool = false
    @State private var showCredentialManagementSheet: Bool = false
    @State private var showChartsAndStatsSheet: Bool = false
    
    @State private var showUpgradeToPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus?
    @State private var showFeaturesDetailsSheet: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        settings.settings.appPurchaseStatus
    }
    
    // MARK: - BODY
    var body: some View {
            Menu {
                // MARK: - Awards button
                Button {
                    showAwardsSheet.toggle()
                } label: {
                    Label("CE Achievements", systemImage: "rosette")
                }//: BUTTON
                
                if paidStatus == .proSubscription {
                    // MARK: - Credential Management Sheet
                    Button {
                        // Action
                        showCredentialManagementSheet = true
                    } label: {
                        Label(
                            "Manage Credentials",
                            systemImage: "person.text.rectangle.fill"
                        )
                    }//: BUTTON
                    
                    // MARK: - Charts Sheet
                    Button {
                        showChartsAndStatsSheet = true
                    } label: {
                        Label("Charts and Stats", systemImage: "chart.bar.xaxis")
                    }//: BUTTON
                    
                } else if paidStatus == .free  {
                    Button {
                        showUpgradeToPaidSheet = true
                    } label: {
                        Label("Paid Options", systemImage: "dollarsign")
                    }//: BUTTON
                }
                // TODO: Add option for folks who only have the basic feature unlock
#if DEBUG
                Button {
                    dataController.deleteAll()
                    dataController.createSampleData()
                } label: {
                    Label("Add Samples", systemImage: "flame")
                }
#endif
                
            } label: {
                Label("App Features and Settings", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
             // MARK: - SHEETS
             .sheet(isPresented: $showChartsAndStatsSheet) {
                 MasterChartsSheet()
             }
             
             .sheet(isPresented: $showCredentialManagementSheet) {
                 CredentialManagementSheet(dataController: dataController)
             }//: SHEET
             
             .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
        
             .sheet(isPresented: $showUpgradeToPaidSheet) {
                 UpgradeToPaidSheet(
                    itemMaxReached: "",
                    learnMore: {type in
                        selectedUpgradeOption = type
                        showFeaturesDetailsSheet = true
                    },
                    purchaseItem: {type in
                        selectedUpgradeOption = type
                        // TODO: Add purchase logic
                    }
                 )
             }//: SHEET
        
             .sheet(isPresented: $showFeaturesDetailsSheet) {
                 if let option = selectedUpgradeOption {
                     FeaturesDetailsSheet(upgradeType: option)
                 }
             }//: SHEET
            
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    SidebarViewTopToolbar()
}

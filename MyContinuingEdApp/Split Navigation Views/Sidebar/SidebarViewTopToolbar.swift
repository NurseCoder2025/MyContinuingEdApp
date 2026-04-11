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
    
    @State private var showAwardsSheet: Bool = false
    @State private var showCredentialManagementSheet: Bool = false
    @State private var showChartsAndStatsSheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    
    @State private var showUpgradeToPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus?
 
    
    // MARK: - COMPUTED PROPERTIES
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
    
    var appStatusText: String {
        switch paidStatus {
        case .free:
            return "Free"
        case .basicUnlock:
            return "Basic"
        case .proSubscription:
            return "Pro"
        }
    }//: appStatusText
    
    // MARK: - BODY
    var body: some View {
        if #available(iOS 17.0, *) {
            HStack {
                Text("CE Cache")
                    .foregroundStyle(.secondary)
                Text(appStatusText)
                    .foregroundStyle(.secondary)
                    .bold()
            }//: HSTACK
            .padding(.leading, 5)
        }//: IF Available
        HStack {
            // The following text fields are only shown in iOS 16 and earlier
            Text("CE Cache")
                .foregroundStyle(.secondary)
            Text(appStatusText)
                .foregroundStyle(.secondary)
                .bold()
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
                        Label("Unlock App", systemImage: "dollarsign")
                    }//: BUTTON
                } else if paidStatus == .basicUnlock {
                    Button {
                        showUpgradeToPaidSheet = true
                    } label: {
                        Label("Upgrade to Pro!", systemImage: "plus.square.fill.on.square.fill")
                    }//: BUTTON
                }
               
#if DEBUG
                Button {
                    dataController.deleteAll()
                    dataController.createSampleData()
                } label: {
                    Label("Add Samples", systemImage: "flame")
                }
#endif
                
                Button {
                    showSettingsSheet = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }//: BUTTON
                
            } label: {
                Label("App Features and Settings", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
        }//: HSTACK
         // MARK: - SHEETS
         .sheet(isPresented: $showChartsAndStatsSheet) {
             MasterChartsSheet()
         }
         
         .sheet(isPresented: $showCredentialManagementSheet) {
             CredentialManagementSheet(dataController: dataController)
         }//: SHEET
         
         .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
    
         .sheet(isPresented: $showUpgradeToPaidSheet) {
             UpgradeToPaidSheet(itemMaxReached: "")
         }//: SHEET
        
         .sheet(isPresented: $showSettingsSheet) {
             SettingsSheet()
         }
            
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    SidebarViewTopToolbar()
}

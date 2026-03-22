//
//  SettingsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/12/25.
//

import SwiftUI

struct SettingsSheet: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    // MARK: - COMPUTED PROPERTIES
    
    var purchaseStatus: PurchaseStatus {
        let savedStatus = dataController.purchaseStatus
        if savedStatus == PurchaseStatus.free.id {
            return PurchaseStatus.free
        } else if savedStatus == PurchaseStatus.basicUnlock.id {
            return PurchaseStatus.basicUnlock
        } else {
            return PurchaseStatus.proSubscription
        }//: IF ELSE
    }//: purchaseStatus
   
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            VStack {
               LeftAlignedTextView(text: "Settings")
                .font(.title)
                .padding(.leading, 10)
                    
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        // MARK: App Purchase Level
                        AppPurchaseLevelView()
                            .padding(.horizontal, 10)
                        
                        // MARK: Subscription/Purchase info
                        PurchaseInfoView()
                            .padding(.horizontal, 10)
                        
                        // MARK: iCloud usage preference for media files
                        // Passing in the DataController as an
                        // argument due to initializing view @State
                        // properties with values from the
                        // sharedSettings in DataController.
                        MediaStorageSettingsView(dataController: dataController)
                            .padding(.horizontal, 10)
                        
                        // MARK: Privacy Settings
                        if purchaseStatus == .proSubscription {
                            PrivacySettingsView()
                                .padding(.horizontal, 10)
                        }//: IF (== .proSubscription)
                        
                        // MARK: General UI Settings
                        GeneralUISettingsView()
                            .padding(.horizontal, 10)
                        
                        // MARK: Notification Settings
                        NotificationSettingsView()
                            .padding(.horizontal, 10)
                        
                        // MARK: Help - contact developer
                        ContactDeveloperView()
                            .padding(.horizontal, 10)
                        
                    }//: LazyVStack
                    
                }//: SCROLL
            }//: VSTACK
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        // TODO: Add action(s)
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                }//: TOOLBAR ITEM
            }//: TOOLBAR
            
        }//: NAV STACK
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    SettingsSheet()
}

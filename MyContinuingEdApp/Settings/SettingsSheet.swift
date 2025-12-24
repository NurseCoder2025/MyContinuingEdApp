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
   
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            VStack {
               LeftAlignedTextView(text: "Settings")
                .font(.title)
                .padding(.leading, 10)
                    
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // App Purchase Level
                        AppPurchaseLevelView()
                            .padding(.horizontal, 10)
                        
                        // Subscription/Purchase info
                        PurchaseInfoView()
                            .padding(.horizontal, 10)
                        
                        // Notification Settings
                        NotificationSettingsView()
                            .padding(.horizontal, 10)
                        
                        // Help - contact developer
                        ContactDeveloperView()
                            .padding(.horizontal, 10)
                        
                    }//: VSTACK
                    
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

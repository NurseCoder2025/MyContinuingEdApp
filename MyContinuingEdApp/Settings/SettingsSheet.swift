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
                    VStack(spacing: 15) {
                        // App Purchase Level
                        AppPurchaseLevelView()
                        
                        // Subscription/Purchase info
                        PurchaseInfoView()
                        
                        // Notification Settings
                        NotificationSettingsView()
                        
                        // Help - contact developer
                        ContactDeveloperView()
                        
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

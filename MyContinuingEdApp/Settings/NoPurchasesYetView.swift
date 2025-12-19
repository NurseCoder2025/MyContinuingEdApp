//
//  NoPurchasesYetView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/18/25.
//

import SwiftUI

struct NoPurchasesYetView: View {
    // MARK: - PROPERTIES
    @State private var showUpgradeOptionsSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        GroupBox {
            VStack {
                Text("Get the most out of this app by purchasing one of three upgrade options. Click on the button below to learn more.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                
                Button {
                    showUpgradeOptionsSheet = true
                } label: {
                    Label("Upgrade Today!", systemImage: "arrow.up.square.fill")
                }//: BUTTON
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
                
            }//: VSTACK
        } label: {
            SettingsHeaderView(headerText: "Support This App!", headerImage: "hands.sparkles.fill")
        }//: GROUP BOX
        // MARK: - SHEETS
        .sheet(isPresented: $showUpgradeOptionsSheet) {
            UpgradeToPaidSheet(itemMaxReached: "")
        }//: SHEET
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    NoPurchasesYetView()
}

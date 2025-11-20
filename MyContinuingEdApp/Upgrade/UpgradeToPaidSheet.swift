//
//  UpgradeToPaidSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct UpgradeToPaidSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    let itemMaxReached: String
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                // MARK: HEADER
                VStack {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(Font.largeTitle.bold())
                        .foregroundStyle(.red)
                    Text("Paid Upgrade Needed")
                        .font(.largeTitle)
                }//: VSTACK
                .accessibilityElement()
                .accessibilityLabel(Text("Attention: Paid Upgrade Needed"))
                
                Text("Sorry! You've added the maximum number of \(itemMaxReached) allowed as a free user. Upgrade to a paid option to remove restrictions and unlock more features.")
                    .padding([.leading, .trailing, .top], 15)
                        
            // MARK: In App Purchase Options
            UpgradeOptionsView()
                
            }//: VSTACK
             // MARK: - TOOlBAR
             .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button {
                         // TODO: Add action(s)
                         dismiss()
                     } label: {
                         Text("Dismiss")
                     }//: BUTTON
                 }//: TOOlBAR ITEM
             }//: TOOlBAR
        }//: NAV VIEW
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    UpgradeToPaidSheet(itemMaxReached: "tags")
}

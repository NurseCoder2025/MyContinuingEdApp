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
    
    // MARK: - COMPUTED PROPERTIES
    var headerText: String {
        if itemMaxReached == "" {
            return "Upgrade to Paid Option"
        } else {
            return itemMaxReached
        }
    }//: headerText
    
    var subHeadText: String {
        if itemMaxReached == "" {
            return "The free version of the app is very limited. Get more features and functionality by selecting one of two in-app purchase options."
        } else {
            return "Sorry! You've added the maximum number of \(itemMaxReached) allowed as a free user. Upgrade to a paid option to remove restrictions and unlock more features."
        }
    }
    
    // MARK: - CLOSURES
    let learnMore: (PurchaseStatus) -> Void
    let purchaseItem: (PurchaseStatus) -> Void
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                // MARK: HEADER
                VStack {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(Font.largeTitle.bold())
                        .foregroundStyle(.red)
                    Text(headerText)
                        .font(.largeTitle)
                }//: VSTACK
                .accessibilityElement()
                .accessibilityLabel(Text("Attention: Paid Upgrade Needed"))
                
                Text(subHeadText)
                    .padding([.leading, .trailing, .top], 15)
                        
            // MARK: In App Purchase Options
                // Closure behaviors are handled in
                // SidebarView (as parent view)
                UpgradeOptionsView(
                    learnMore: learnMore,
                    buyItem: purchaseItem
                )
                
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
    // MARK: - INIT
    init(itemMaxReached: String, learnMore: @escaping (PurchaseStatus) -> Void, purchaseItem: @escaping (PurchaseStatus) -> Void) {
        self.itemMaxReached = itemMaxReached
        self.learnMore = learnMore
        self.purchaseItem = purchaseItem
    }//: INIT
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    UpgradeToPaidSheet(
        itemMaxReached: "tags",
        learnMore: {_ in },
        purchaseItem: {_ in}
    )
}

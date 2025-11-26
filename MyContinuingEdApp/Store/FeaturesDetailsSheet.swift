//
//  FeaturesDetailsSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct FeaturesDetailsSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    let upgradeType: PurchaseStatus
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                // MARK: HEADER
                FeaturesDetailsHeaderView(upgradeType: upgradeType)
                Divider()
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack {
                        // MARK: Details Rows
                        if upgradeType == .basicUnlock {
                            ForEach(basicFeatures) { feature in
                                FeaturesDetailsRowView(
                                    feature: feature,
                                    upgradeType: .basicUnlock)
                            }//: LOOP
                        } else if upgradeType == .proSubscription {
                            ForEach(proFeatures) {feature in
                                FeaturesDetailsRowView(
                                    feature: feature,
                                    upgradeType: .proSubscription
                                )
                            }//: LOOP
                        }//: IF ELSE
                    }//: LAZY V STACK
                }//: SCROLL
            }//: VStack
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                }//: TOOlBAR ITEM (dismiss)
                
            }//: TOOlBAR
        }//: NAV VIEW
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    FeaturesDetailsSheet(upgradeType: .basicUnlock)
}


#Preview {
    FeaturesDetailsSheet(upgradeType: .proSubscription)
}

//
//  UpgradeOptionsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct UpgradeOptionsView: View {
    // MARK: - PROPERTIES
    @State private var currentCardIndex: Int = 0
    @State private var selectedUpgradeOption: PurchaseStatus?
    
    // MARK: - CLOSURES
    let buyItem: (PurchaseStatus) -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            TabView(selection: $currentCardIndex) {
                AppUpgradeCardView(
                    purchaseType: .proSubscription,
                    headerText: "CE Cache Pro Subscription",
                    briefDescription: "Everything in the basic feature unlock PLUS...",
                    purchasePrice: 24.99,
                    purchaseDescription: "Annual Subscription",
                    cardHeight: 2,
                    onLearnMore: {_ in
                        selectedUpgradeOption = .proSubscription
                    } ,
                    onPurchase: buyItem
                )
                .tag(0)
                
                AppUpgradeCardView(
                    purchaseType: .basicUnlock,
                    headerText: "Basic Feature Unlock",
                    briefDescription: "Essential features for tracking CEs for one credential",
                    purchasePrice: 14.99,
                    purchaseDescription: "One-time purchase",
                    cardHeight: 2.5,
                    onLearnMore: {_ in
                        selectedUpgradeOption = .basicUnlock
                    },
                    onPurchase: buyItem
                )
                .tag(1)
                
            }//: TAB VIEW
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
             // MARK: Page Indicator
            HStack {
                ForEach(0..<2, id: \.self) { count in
                    Circle()
                        .fill(count == currentCardIndex ? Color.yellow : Color.gray)
                        .frame(width: 10, height: 10)
                        .padding(5)
                }//: LOOP
            }//: HSTACK
        }//: VStack
        
        // MARK: - SHEETS
        .sheet(item: $selectedUpgradeOption) { option in
                FeaturesDetailsSheet(upgradeType: option)
        }//: SHEET
        
    }//: BODY
    // MARK: - INIT
    init(buyItem: @escaping (PurchaseStatus) -> Void) {
        self.buyItem = buyItem
    }
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    UpgradeOptionsView(buyItem: {_ in})
}

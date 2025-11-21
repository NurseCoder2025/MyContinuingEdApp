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
    
    var featureCards: [AppUpgradeCardView] {
        [
            AppUpgradeCardView(
                purchaseType: .proSubscription,
                headerText: "CE Cache Pro Subscription",
                briefDescription: "Everything in the basic feature unlock PLUS...",
                purchasePrice: 24.99,
                purchaseDescription: "Annual Subscription",
                cardHeight: 2,
                onLearnMore: learnMore,
                onPurchase: buyItem
            ),
            AppUpgradeCardView(
                purchaseType: .basicUnlock,
                headerText: "Basic Feature Unlock",
                briefDescription: "Essential features for tracking CEs for one credential",
                purchasePrice: 14.99,
                purchaseDescription: "One-time purchase",
                cardHeight: 2.5,
                onLearnMore: learnMore,
                onPurchase: buyItem
            )
        ]
    }
    
    // MARK: - CLOSURES
    let learnMore: (PurchaseStatus) -> Void
    let buyItem: (PurchaseStatus) -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView([.horizontal], showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(featureCards.indices, id: \.self) { index in
                                featureCards[index].frame(width: geo.size.width)
                                    .id(index)
                            }//: LOOP
                            
                        }//: HSTACK
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let offset = value.translation.width
                                    if offset < -50 && currentCardIndex < featureCards.count - 1 {
                                        currentCardIndex += 1
                                    } else if offset > 50 && currentCardIndex > 0 {
                                        currentCardIndex -= 1
                                    }
                                }//: ON ENDED
                        )//: GESTURE
                    }//: SCROLL
                    .onChange(of: currentCardIndex) { newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }//: ON CHANGE
                }//: SCROLL READER
            }//: GEO READER
             // MARK: Page Indicator
            HStack {
                ForEach(0..<featureCards.count, id: \.self) { count in
                    Circle()
                        .fill(count == currentCardIndex ? Color.yellow : Color.gray)
                        .frame(width: 10, height: 10)
                        .padding(5)
                }//: LOOP
            }//: HSTACK
        }//: VStack
    }//: BODY
    // MARK: - INIT
    init(learnMore: @escaping (PurchaseStatus) -> Void, buyItem: @escaping (PurchaseStatus) -> Void) {
        self.learnMore = learnMore
        self.buyItem = buyItem
    }
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    UpgradeOptionsView(learnMore: {_ in }, buyItem: {_ in})
}

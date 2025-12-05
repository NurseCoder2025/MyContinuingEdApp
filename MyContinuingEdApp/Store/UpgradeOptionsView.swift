//
//  UpgradeOptionsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import StoreKit
import SwiftUI

struct UpgradeOptionsView: View {
    // MARK: - PROPERTIES
    @State private var currentCardIndex: Int = 0
    @State private var selectedUpgradeOption: PurchaseStatus?
    @State private var availableProducts: [Product] = []
    @State private var showCodeRedemptionSheet: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    
    // MARK: - CLOSURES
    let buyItem: (Product) -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            TabView(selection: $currentCardIndex) {
                ForEach(availableProducts) { prod in
                   AppUpgradeCardView(
                    product: prod,
                    cardHeight: 2,
                    onLearnMore: { prodId in
                        switch prodId {
                        case DataController.basicUnlocKID:
                            selectedUpgradeOption = .basicUnlock
                        default:
                            selectedUpgradeOption = .proSubscription
                        }
                    },
                    onPurchase: {product in
                        buyItem(product)
                    },
                    redeemCode: {
                        showCodeRedemptionSheet = true
                    },
                    restorePurchases: {
                        // TODO: Add logic here
                    }
                   )//: AppUpgradeCardView
                   .offerCodeRedemption(isPresented: $showCodeRedemptionSheet)
                }//: LOOP
                
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
        // MARK: - TASK
        .task {
            do {
                let prodIdentifiers = [DataController.basicUnlocKID, DataController.proAnnualID, DataController.proMonthlyID]
                
                let allProducts: Set<Product> = Set(try await Product.products(for: prodIdentifiers))
                var userPurchasedProds: Set<Product> = []
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction):
                        for prod in allProducts where prod.id == transaction.productID {
                            userPurchasedProds.insert(prod)
                        }
                    case .unverified:
                        continue
                    }//: SWITCH
                    
                    availableProducts = Array(allProducts.subtracting(userPurchasedProds))
                }//: FOR AWAIT
                
            } catch {
                print("Unable to retrieve any products from the App Store.")
            }
            
        }//: TASK
        
        // MARK: - SHEETS
        .sheet(item: $selectedUpgradeOption) { option in
                FeaturesDetailsSheet(upgradeType: option)
        }//: SHEET
        
        
    }//: BODY
    // MARK: - INIT
    init(buyItem: @escaping (Product) -> Void) {
        self.buyItem = buyItem
    }
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    UpgradeOptionsView(buyItem: {_ in})
}

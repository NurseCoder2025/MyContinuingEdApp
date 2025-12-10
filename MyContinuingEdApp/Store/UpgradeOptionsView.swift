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
    @EnvironmentObject var dataController: DataController
    
    @State private var currentCardIndex: Int = 0
    @State private var selectedUpgradeOption: PurchaseStatus?
    @State private var loadingState: LoadState = .loading
    @State private var showCodeRedemptionSheet: Bool = false
    
    // MARK: - CLOSURES
    let buyItem: (Product) -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            switch loadingState {
            case .loading:
                Text("Fetching offers...")
                    .font(.title2.bold())
                    .padding(.top, 20)
                ProgressView()
                    .controlSize(.large)
            case .loaded:
                TabView(selection: $currentCardIndex) {
                    ForEach(Array(dataController.products.enumerated()), id: \.element.id) { index, prod in
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
                            restore()
                        }
                       )//: AppUpgradeCardView
                       .offerCodeRedemption(isPresented: $showCodeRedemptionSheet)
                       .tag(index)
                    }//: LOOP
                    
                }//: TAB VIEW
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
                
                
                
                 // MARK: Page Indicator
                HStack {
                    ForEach(0..<dataController.products.count, id: \.self) { count in
                        Circle()
                            .fill(count == currentCardIndex ? Color.yellow : Color.gray)
                            .frame(width: 10, height: 10)
                            .padding(5)
                    }//: LOOP
                }//: HSTACK
            case .error:
                VStack {
                    Text("Sorry, there was an error loading in-app purchase options from the App Store.")
                    
                    Button("Try Again") {
                        Task {
                            await load()
                        }
                    }//: Button
                    .padding(.top, 5)
                }//: VSTACK
                .padding(.top, 15)
                .padding([.leading, .trailing], 5)
            }//: SWITCH
            
        }//: VStack
        // MARK: - TASK
        .task {
            await load()
        }

        // MARK: - SHEETS
        .sheet(item: $selectedUpgradeOption) { option in
                FeaturesDetailsSheet(upgradeType: option)
        }//: SHEET
        
        
    }//: BODY
    
    // MARK: - FUNCTIONS
    /// Function that sets the loadingState property for UpgradeOptionsView by calling the
    /// DataController's loadProducts() method.  If the method throws an error or if the @Published
    /// array of products in DataController is empty, then the loadingState is changed to .error.
    func load() async {
        loadingState = .loading
        
        do {
            try await dataController.loadProducts()
            
            if dataController.products.isEmpty {
                loadingState = .error
            } else {
                loadingState = .loaded
            }
        } catch {
            loadingState = .error
        }
    }
    
    /// Function that forces a re-sync of app transaction information with the AppStore.  Only called
    /// when the user taps the Restore Purchases button.
    func restore() {
        Task {
            try await AppStore.sync()
        }//: TASK
    }//: RESTORE()
    
    // MARK: - INIT
    init(buyItem: @escaping (Product) -> Void) {
        self.buyItem = buyItem
    }
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    UpgradeOptionsView(buyItem: {_ in})
}

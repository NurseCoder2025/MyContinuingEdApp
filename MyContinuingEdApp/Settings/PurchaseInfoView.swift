//
//  SubscriptionInfoView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/15/25.
//

import StoreKit
import SwiftUI

struct PurchaseInfoView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @State private var productLoadingStatus: LoadState = .loading
    
    @State private var purchasedProds: [(Product, Date)] = []
    @State private var subRenewalDate: Date?
    @State private var subTransactionID: UInt64 = 0
    @State private var basicUnlockTransactionID: UInt64 = 0
    
    @State private var showManageSubscriptionSheet: Bool = false
    @State private var showRefundSheetForSubscription: Bool = false
    @State private var showRefundSheetForBasicUnlock: Bool = false
    @State private var showUpgradeToProSheet: Bool = false
    
    @State private var showProductLoadingIssueAlert: Bool = false
    
    let currentDevice = ProcessInfo()
    
    // MARK: - COMPUTED PROPERTIES
    /// Computed property returning true if the app is being run on a device which supports the
    /// manageSubscriptionsSheet(isPresented:) or not.  Depends on a local constant, currentDevice,
    /// which is an instance of ProcessInfo().
    var deviceSupportsSubManagementSheet: Bool {
        return !currentDevice.isMacCatalystApp && !currentDevice.isiOSAppOnMac
    }
    
    var subscribedProduct: (Product, Date)? {
        for item in purchasedProds {
            let prod = item.0
            if prod.type == .autoRenewable {
                return item
            }
        }//: LOOP
        return nil
    }//: subscribedProduct
    
    var basicUnlockProduct: (Product, Date)? {
        for item in purchasedProds {
            let prod = item.0
            if prod.type == .nonConsumable {
                return item
            }
        }//: LOOP
        return nil
    }//: basicUnlockProduct
    
    // MARK: - BODY
    var body: some View {
        VStack {
            switch productLoadingStatus {
                // MARK: - LOADING
            case .loading:
                VStack {
                    Text("Fetching purchases...")
                        .font(.title).bold()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .padding(.top, 10)
                    
                }//: VSTACK
                .accessibilityLabel(Text("Loading purchases..."))
                // MARK: - LOADED
            case .loaded:
                if purchasedProds.isEmpty {
                    NoPurchasesYetView()
                } else {
                    VStack {
                        // Group for Subscription (if applicable)
                        if let subscription = subscribedProduct?.0, let purchaseDate = subscribedProduct?.1, let _ = subscription.subscription, let renewalDay = subRenewalDate {
                            GroupBox {
                                HStack{
                                    // TODO: Add image
                                    VStack {
                                        Text(subscription.displayName.localizedCapitalized)
                                        Text("Purchased on: \(purchaseDate.formatted(date: .numeric, time: .omitted))")
                                        Text("Subscription ends: \(renewalDay.formatted(date: .numeric, time: .omitted))")
                                    }//: VSTACK
                                }//: HSTACK
                                
                                Divider()
                                
                                if deviceSupportsSubManagementSheet {
                                    Button {
                                        showManageSubscriptionSheet.toggle()
                                    } label: {
                                        Text("Manage Subscription")
                                    }//: BUTTON
                                } else {
                                    Button {
                                        showRefundSheetForSubscription.toggle()
                                    } label: {
                                        Text("Cancel Subscription")
                                    }//: BUTTON
                                }
                                
                            } label: {
                                SettingsHeaderView(headerText: "Subscription Info", headerImage: "calendar.badge.clock.rtl")
                            }//: GROUP BOX
                        }
                        
                        // Group for Basic Unlock purchase (if applicable)
                        if let basicProduct = basicUnlockProduct {
                            GroupBox {
                                HStack {
                                    // TODO: Add image here
                                    VStack {
                                        HStack {
                                            Text("CE Cache Basic Unlock")
                                                .bold()
                                            Spacer()
                                        }//: HSTACK
                                        
                                        HStack {
                                            Text("Purchased on: \(basicProduct.1.formatted(date: .numeric, time: .omitted))")
                                            Spacer()
                                        }//: HSTACK
                                        
                                    }//: VSTACK
                                }//: HSTACK
                                
                                if subscribedProduct == nil {
                                    Divider()
                                    Button {
                                        showUpgradeToProSheet = true
                                    } label: {
                                        Text("Subscribe to CE Cache Pro!")
                                    }//: BUTTON
                                    .buttonStyle(.borderedProminent)
                                }//: IF
                                
                                Divider()
                                Button {
                                    showRefundSheetForBasicUnlock = true
                                } label: {
                                    Text("Request a refund")
                                }//: BUTTON
                                
                            } label: {
                                SettingsHeaderView(headerText: "One-Time Purchases", headerImage: "dollarsign")
                            }
                        }//: IF LET
                        
                    }//: VSTACK
                     // MARK: - SHEETS
                    .manageSubscriptionsSheet(isPresented: $showManageSubscriptionSheet)
                    .refundRequestSheet(for: subTransactionID, isPresented: $showRefundSheetForSubscription)
                    .refundRequestSheet(
                        for: basicUnlockTransactionID,
                        isPresented: $showRefundSheetForBasicUnlock
                    )
                    .sheet(isPresented: $showUpgradeToProSheet) {
                        UpgradeToPaidSheet(itemMaxReached: "")
                    }//: SHEET
                    
                    // MARK: - ALERTS
                    .alert("Problem Loading Purchases",isPresented: $showProductLoadingIssueAlert) {
                    } message: {
                        Text("There was an issue loading purchases from the App Store. Check your network connection and try again.")
                    }
                    
                }//: IF ELSE
                 // MARK: - ERROR
            case .error:
                VStack {
                    Text("Sorry, but there was an error loading your purchases from the App Store.")
                    
                    Button("Try Again") {
                        Task {
                            try await loadPurchasedProducts()
                        }//: TASK
                    }//: BUTTON
                    .padding(.top, 5)
                    
                }//: VSTACK
                .padding(.top, 15)
                .padding([.leading, .trailing], 5)
            }//: SWITCH
        }//: VSTACK
         // MARK: - TASK
         .task {
             do {
                try await loadPurchasedProducts()
                 productLoadingStatus = .loaded
             } catch {
                productLoadingStatus = .error
                showProductLoadingIssueAlert = true
             }
         }//: TASK
    }//: BODY
    
    // MARK: - METHODS
    /// Method for loading all products that the user has purchased, whether a subscription
    /// and/or the basic unlock in-app purchase (one-time).  Saves results to the purchasedProds
    /// array in PurchaseInfoView.
    @MainActor
    private func loadPurchasedProducts() async throws {
        productLoadingStatus = .loading
        
        let prodIds = [
            DataController.basicUnlocKID,
            DataController.proMonthlyID,
            DataController.proAnnualID
        ]
        let allProducts: Set<Product> = Set(try await Product.products(for: prodIds))
        
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                for prod in allProducts where prod.id == transaction.productID {
                    let purchasedItem = prod
                    let purchaseDate = transaction.purchaseDate
                    purchasedProds.append( (purchasedItem, purchaseDate) )
                    
                    if let subscription = prod.subscription {
                        subTransactionID = transaction.id
                        let groupID = subscription.subscriptionGroupID
                        let statuses = try await Product.SubscriptionInfo.status(for: groupID)
                        if let status = statuses.first {
                            let renewalVerification = status.renewalInfo
                            if case let .verified(renewalInfo) = renewalVerification {
                                subRenewalDate = renewalInfo.renewalDate
                            }//: IF CASE LET
                            
                        }//: IF LET (status)
                    } else if prod.id == DataController.basicUnlocKID {
                        basicUnlockTransactionID = transaction.id
                    }//: IF LET (subscription)
                }//: LOOP
            }//: IF CASE LET
        }//: FOR AWAIT
    }//: loadPurchasedProducts()
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PurchaseInfoView()
}

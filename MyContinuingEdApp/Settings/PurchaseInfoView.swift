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
    
    // Pro Downgrade
    @State private var showProDowngradeWarning: Bool = false
    @State private var showDowngradeFailedAlert: Bool = false
    @State private var downGradeAlertMessage: String = ""
    
    let currentDevice = ProcessInfo()
    
    let basicUnlockMessageForProUsers: String = """
        Since you are currently a Pro subscriber (thank you!), you have full app access as long as your subscription remains active.  Should it end then you will be downgraded to the basic unlock feature set. 
        """
    
    // MARK: - COMPUTED PROPERTIES
    /// Computed property returning true if the app is being run on a device which supports the
    /// manageSubscriptionsSheet(isPresented:) or not.  Depends on a local constant, currentDevice,
    /// which is an instance of ProcessInfo().
    var deviceSupportsSubManagementSheet: Bool {
        return !currentDevice.isMacCatalystApp && !currentDevice.isiOSAppOnMac
    }//: deviceSupportsSubManagementSheet
    
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
    
    var userPurchasedCore: Bool {
        if let corePurchased = basicUnlockProduct {
            return true
        } else {
            return false
        }//: IF LET (corePurchased)
    }//: userPurchasedCore
    
    var userHasAProSubscription: Bool {
        return (purchasedProds.filter {$0.0.type == .autoRenewable}).count > 0
    }//: userHasAProSubscription
    
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
                    VStack(spacing: 20) {
                        // MARK: - Subscription
                        if let subscription = subscribedProduct?.0,
                            let purchaseDate = subscribedProduct?.1,
                            let renewalDay = subRenewalDate {
                                GroupBox {
                                    HStack{
                                        // TODO: Add image
                                        VStack {
                                            LeftAlignedTextView(text: subscription.displayName.localizedCapitalized)
                                                .font(.title2).bold()
                                                .foregroundStyle(Color.purple)
                                            
                                            HStack {
                                                LeftAlignedTextView(text: "Purchased on: ")
                                                Text("\(purchaseDate.formatted(date: .numeric, time: .omitted))")
                                                    .bold()
                                            }//: HStack
                                            
                                            HStack {
                                                LeftAlignedTextView(text: "Subscription renews: ")
                                                Text("\(renewalDay.formatted(date: .numeric, time: .omitted))")
                                                    .bold()
                                                    .foregroundStyle(Color.orange)
                                            }//: HSTACK
                                        }//: VSTACK
                                    }//: HSTACK
                                    
                                    Divider()
                                    
                                        // MARK: CANCEL PRO SUBSCRIPTION
                                        Button {
                                            showProDowngradeWarning = true
                                        } label: {
                                            Text("Cancel Subscription")
                                        }//: BUTTON
                                        .buttonStyle(.bordered)
                                    
                                } label: {
                                    SettingsHeaderView(headerText: "Subscription Info", headerImage: "calendar.badge.clock.rtl")
                                }//: GROUP BOX
                        }//: IF LET (subscription, purchaseDate, renewalDay)
                        
                        // MARK: - Basic Unlock
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
                                        
                                        // MARK: Message for Pro + Basic Unlock Users
                                        if subscribedProduct != nil {
                                            LeftAlignedTextView(text: basicUnlockMessageForProUsers)
                                                .font(.caption)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 5)
                                        }//: IF
                                        
                                    }//: VSTACK
                                }//: HSTACK
                                
                                // MARK: Upgrade to Pro
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
                                
                                // MARK: REFUND
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
                    // MARK: - ON CHANGE
                    
                     // MARK: - SHEETS
                    .manageSubscriptionsSheet(isPresented: $showManageSubscriptionSheet)
                    .refundRequestSheet(for: subTransactionID, isPresented: $showRefundSheetForSubscription) //: REFUND SHEET (PRO SUBSCRIPTION)
                    
                    .refundRequestSheet(
                        for: basicUnlockTransactionID,
                        isPresented: $showRefundSheetForBasicUnlock
                    )//: REFUND SHEET (CORE)
                    
                    .sheet(isPresented: $showUpgradeToProSheet) {
                        UpgradeToPaidSheet(itemMaxReached: "")
                    }//: SHEET
                    
                    // MARK: - ALERTS
                    .alert("Problem Loading Purchases",isPresented: $showProductLoadingIssueAlert) {
                    } message: {
                        Text("There was an issue loading purchases from the App Store. Check your network connection and try again.")
                    }//: ALERT (problem loading purchases)
                    
                    .alert("Downgrade Request Failed", isPresented: $showDowngradeFailedAlert) {
                        Button("OK") {}
                    } message: {
                        Text(downGradeAlertMessage)
                    }//: ALERT (downgrade request failed)
                    
                    // MARK: - CONFIRMATION DIALOGS
                    .confirmationDialog("Downgrade Notice", isPresented: $showProDowngradeWarning) {
                        Button("Downgrade", role: .destructive){
                            if deviceSupportsSubManagementSheet {
                                showManageSubscriptionSheet = true
                            } else {
                                showRefundSheetForSubscription = true
                            }//:  IF ELSE (deviceSupportsSubManagementSheet)
                        }//: BUTTON (Downgrade)
                        Button("Cancel", role: .cancel) {}//: Button (cancel)
                    } message: {
                        Text("If you choose to downgrade from Pro, all but one existing credential will be deleted (you will need to select which one to keep) along with their renewal periods (but not associated CE activities), any certificates uploaded in iCloud that are not for the current renewal will be removed along with all audio recordings, in addition to the loss of all other Pro features. This will occur once the app recieves confirmation of your refund from Apple.")
                    }//: ALERT (Pro Downgrade)
                    
                }//: IF ELSE (purchasedProds.isEmpty)
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
                            if case let .verified(subTransAct) = status.transaction {
                                subRenewalDate = subTransAct.expirationDate
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

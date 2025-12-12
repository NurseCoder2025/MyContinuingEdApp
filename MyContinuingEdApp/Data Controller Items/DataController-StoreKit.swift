//
//  DataController-StoreKit.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/25/25.
//

import Foundation
import StoreKit


extension DataController {
    // MARK: - In App Purchase IDs
    // TODO: Update IDs once bundle identifier has been updated to a real one
    static let basicUnlocKID = "com.TheEmpire.basicFeatureUnlock"
    static let proAnnualID = "com.TheEmpire.annualPro"
    static let proMonthlyID = "com.TheEmpire.monthlyPro"
    
    // MARK: - Store related settings
    /// Computed property which controls the current paid status for the app by accessing
    /// the sharedSettings @Published property in DataController.
    ///
    /// This property is based on the NSUbiquitousKeyValueStore.default, which is assigned to the
    /// sharedSettings property.  This allows for automatic syncing in iCloud between devices. In
    /// order to keep things simple, the value for the key ("purchaseStatus") is a String value.
    /// When using this property, be sure to use the id computed property for each case in the
    /// PurchaseStatus enum as that returns a string value for each status.  The getter will return
    /// the "free" string from the PurchaseStatus.free.id if the purchaseStatus key has not been
    /// created yet.
    var purchaseStatus: String {
        get {
            sharedSettings.string(forKey: "purchaseStatus") ?? PurchaseStatus.free.id
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "purchaseStatus")
        }
    }//: purchaseStatus
    
    // MARK: - Loading Products
    @MainActor
    func loadProducts() async throws {
        guard products.isEmpty else { return }
        
        try await Task.sleep(for: .seconds(2))
        
        let prodIds = [Self.basicUnlocKID, Self.proAnnualID, Self.proMonthlyID]
        let allProducts: Set<Product> = Set(try await Product.products(for: prodIds))
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
        }//: FOR AWAIT
        
        let availableProds = Array(allProducts.subtracting(userPurchasedProds))
        let firstProd = availableProds.first(where: {$0.id == Self.proAnnualID})
        let secondProd = availableProds.first(where: {$0.id == Self.proMonthlyID})
        let thirdProd = availableProds.first(where: {$0.id == Self.basicUnlocKID})
        
        products = [firstProd, secondProd, thirdProd].compactMap(\.self)
        
        #if DEBUG
        print("Loaded Products: \(products.count)")
        #endif
        
    }//: loadProducts()
    
    // MARK: - Transaction Handling
    /// Function for finalizing in-app purchase transactions, including refunds.
    /// Updates the sharedSettings property in DataController with the key "purchaseStatus" with
    /// a string representing the state of the app, whether in free mode, basic unlock, or in
    /// subscription mode.  The string comes from the PurchaseStatus enum's id property.
    /// - Parameter transaction: In-app purchase transaction
    @MainActor
    func finalizeTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            if transaction.productID == Self.basicUnlocKID {
                // In the rare event that a user purchases a basic unlock
                // while having an active subscription, keeping the
                // purchaseStatus as the subscription
                for await entitlement in Transaction.currentEntitlements {
                    if case let .verified(transaction) = entitlement,
                       (transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID)
                    {
                        purchaseStatus = PurchaseStatus.proSubscription.id
                        return
                    }
                }//: LOOP (for await)
                purchaseStatus = PurchaseStatus.basicUnlock.id
            } else if transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID {
               purchaseStatus = PurchaseStatus.proSubscription.id
            }//: ELSE IF
            await transaction.finish()
        } else {
            // Handling refunds/cancellations/subscription expiring
            // Note: in the case of subscriptions, the grace period
            // option will be used so an expired subscription won't be
            // broadcasted until after that point in time
            if transaction.productID ==  Self.basicUnlocKID {
                // check current entitlements to see if the user has
                // an active subscription (not likely), and if so,
                // set the purchase status to that; otherwise set
                // the purchaseStatus property to free
                for await entitlement in Transaction.currentEntitlements {
                    if case let .verified(transaction) = entitlement {
                        if transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID {
                            purchaseStatus = PurchaseStatus.proSubscription.id
                        } else {
                            purchaseStatus = PurchaseStatus.free.id
                        }
                    }//: IF LET
                }//: LOOP (for await)
            } else {
                // Check current entitlements to see if the user ever
                // purchased the basic lock in the past, and if so,
                // enable basic unlock features; otherwise, set app to
                // free mode
                for await entitlement in Transaction.currentEntitlements {
                    if case let .verified(transaction) = entitlement, transaction.productID == Self.basicUnlocKID {
                        purchaseStatus = PurchaseStatus.basicUnlock.id
                    } else {
                        purchaseStatus = PurchaseStatus.free.id
                    }
                }//: LOOP (for await)
            }//: IF ELSE
            await transaction.finish()
        }//: IF ELSE
    }//: finalizeTransaction
    
    
    func monitorTransactions() async {
        // Checking for previous purchases
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                await finalizeTransaction(transaction)
            }//: IF CASE LET
        }//: for await
        
        // Checking for future transactions coming in
        for await update in Transaction.updates {
            if let transaction = try? update.payloadValue {
                await finalizeTransaction(transaction)
            }//: IF LET
        }//: for await
    }//: monitorTransactions()
    
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        if case let .success(validation) = result {
            try await finalizeTransaction(validation.payloadValue)
            return true
        } else {
            return false
        }
    }//: purchase
    
    
    
    
    
}//: DATA CONTROLLER

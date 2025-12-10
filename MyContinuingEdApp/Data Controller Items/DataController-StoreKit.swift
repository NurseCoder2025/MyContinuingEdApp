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
        
    }//: loadProducts()
    
    // MARK: - Transaction Handling
    /// Function for finalizing in-app purchase transactions that are not refunds.  Updates the settings.json file to reflect
    /// what was purchased (either basic feature unlock or the pro subscription).  For the subscription, sets status to
    /// active.
    /// - Parameter transaction: In-app purchase transaction
    @MainActor
    func finalizeTransaction(_ transaction: Transaction) async {
        var appSettings = accessUserSettings()
        if transaction.revocationDate == nil {
            if transaction.productID == Self.basicUnlocKID {
                appSettings?.appPurchaseStatus = .basicUnlock
                appSettings?.basicUnlockPurchased = true
                
                if let moddedSettings = appSettings {
                    modifyUserSettings(moddedSettings)
                }//: IF LET
            } else if transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID {
               
                appSettings?.appPurchaseStatus = .proSubscription
                appSettings?.proSubscriptionPurchased = true
                appSettings?.subscriptionStatus = .active
                
                if let moddedSettings = appSettings {
                    modifyUserSettings(moddedSettings)
                }
            }//: ELSE IF
            await transaction.finish()
        } else {
            // Handling refunds/cancellations
            if transaction.productID ==  Self.basicUnlocKID {
                appSettings?.basicUnlockPurchased = false
                if appSettings?.subscriptionStatus == .active {
                    appSettings?.appPurchaseStatus = .proSubscription
                } else {
                    appSettings?.appPurchaseStatus = .free
                }
                
                if let moddedSettings = appSettings {
                    modifyUserSettings(moddedSettings)
                }
            } else {
                appSettings?.subscriptionStatus = .inactive
                appSettings?.proSubscriptionPurchased = false
                if appSettings?.basicUnlockPurchased == true {
                    appSettings?.appPurchaseStatus = .basicUnlock
                } else {
                    appSettings?.appPurchaseStatus = .free
                }
                
                if let moddedSettings = appSettings {
                    modifyUserSettings(moddedSettings)
                }
            }
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
    
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        if case let .success(validation) = result {
            try await finalizeTransaction(validation.payloadValue)
        }
    }//: purchase
    
    // MARK: - Subscription OFFERS
    func isUserEligibleForIntroOffer() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                if transaction.productID == DataController.proAnnualID || transaction.productID == DataController.proMonthlyID {
                    return false
                }
            }//: if case let
        }//: for await
        return true
    }//: isUserEligibleForIntroOffer()
    
    func getSubscriptionIntroOfferText(for product: Product, isEligible: Bool) -> String {
        guard let subscription = product.subscription else {
            return "No subscription info available"
        }
        
        if isEligible, let offer = subscription.introductoryOffer {
            let price = offer.displayPrice
            let period = offer.period.unit == .month ? "\(offer.period.value) month(s)" : "\(offer.period.value) year(s)"
            
            let standardPeriod = "\(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit)"
            
            return "\(price) for \(period), then \(product.displayPrice) for \(standardPeriod)"
            
        } else {
            let standardPeriod = "\(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit)"
            return "\(product.displayPrice) for \(standardPeriod)"
        }
            
    }//: getSubscriptionIntroOfferText
    
    
}//: DATA CONTROLLER

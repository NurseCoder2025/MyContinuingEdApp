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
    
}//: DATA CONTROLLER

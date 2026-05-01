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
    static let proLifetimeID = "com.TheEmpire.proLifetime"
    
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
            settingsCache.appPurchaseLevel = newValue
            settingsCache.encodeCurrentState()
        }
    }//: purchaseStatus
    
    // MARK: - Loading Products
    @MainActor
    func loadProducts() async throws {
        try await Task.sleep(for: .seconds(0.2))
        
        let prodIds = [Self.basicUnlocKID, Self.proAnnualID, Self.proMonthlyID, Self.proAnnualID]
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
        let fourthProd = availableProds.first(where: {$0.id == Self.proLifetimeID})
        
        products = [firstProd, secondProd, thirdProd, fourthProd].compactMap(\.self)
        
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
                if await revertPurchaseToSubscriptionStatus() {
                    return
                } else {
                    purchaseStatus = PurchaseStatus.basicUnlock.id
                }//: IF AWAIT (revertPurchaseToSubscriptionStatus())
            } else if transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID {
               purchaseStatus = PurchaseStatus.proSubscription.id
                if transaction.productID == Self.proAnnualID {
                    currentSubscriptionType = "annual"
                } else if transaction.productID == Self.proMonthlyID {
                    currentSubscriptionType = "monthly"
                }
            } else if transaction.productID == Self.proLifetimeID {
                purchaseStatus = PurchaseStatus.proLifetime.id
            }//: IF ELSE
            await transaction.finish()
        } else {
            // Handling refunds/cancellations/subscription expiring
            // Note: in the case of subscriptions, the grace period
            // option will be used so an expired subscription won't be
            // broadcasted until after that point in time
            await downgradeFromProduct(having: transaction.productID)
            await transaction.finish()
        }//: IF ELSE
    }//: finalizeTransaction
    
    
    private func downgradeFromProduct(having prodID: Product.ID) async {
        if prodID ==  Self.proLifetimeID {
            // check current entitlements to see if the user has
            // an active subscription or basic unlock (not likely), and if so,
            // set the purchase status to that; otherwise set
            // the purchaseStatus property to free
            if await revertPurchaseToSubscriptionStatus() {
                return
                // Check current entitlements to see if the user ever
                // purchased the basic lock in the past, and if so,
                // enable basic unlock features; otherwise, set app to
                // free mode
            } else if await revertPurchaseToBasicUnlockStatus() {
                downgradeMade = .proToCore
                credentialSelectionNeeded = true
                return
            } else {
                downgradeMade = .proToFree
                credentialSelectionNeeded = true
                revertPurchaseToFreeStatus()
            }//: IF AWAIT
        } else if prodID == Self.proAnnualID || prodID == Self.proMonthlyID {
            // calling this method in-case the user has a different subscription plan
            // in-effect (ex. cancelled annual but has monthly)
            if await revertPurchaseToSubscriptionStatus() {
                return
            } else if await revertPurchaseToLifetimeStatus() {
                return
                // Check current entitlements to see if the user ever
                // purchased the basic lock in the past, and if so,
                // enable basic unlock features; otherwise, set app to
                // free mode
            } else if await revertPurchaseToBasicUnlockStatus() {
                downgradeMade = .proToCore
                credentialSelectionNeeded = true
                return
            } else {
                downgradeMade = .proToFree
                credentialSelectionNeeded = true
                revertPurchaseToFreeStatus()
            }//: IF ELSE
        } else if prodID == Self.basicUnlocKID {
            if await revertPurchaseToLifetimeStatus() {
                return
            } else if await revertPurchaseToSubscriptionStatus() {
                return
            } else {
                downgradeMade = .coreToFree
                revertPurchaseToFreeStatus()
            }//: IF ELSE
        }//: IF ELSE (prodID == )
    }//: downgradeFromBasicUnlock
    
    private func revertPurchaseToSubscriptionStatus() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                if transaction.productID == Self.proAnnualID || transaction.productID == Self.proMonthlyID {
                    purchaseStatus = PurchaseStatus.proSubscription.id
                    if transaction.productID == Self.proAnnualID {
                        currentSubscriptionType = "annual"
                        return true
                    } else if transaction.productID == Self.proMonthlyID {
                        currentSubscriptionType = "monthly"
                        return true
                    }//: IF ELSE
                }//: IF (productID == proAnnualID OR proMonthlyID)
            }//: IF LET
        }//: LOOP
        return false
    }//: revertPurchaseToSubscriptionStatus
    
    private func revertPurchaseToBasicUnlockStatus() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement, transaction.productID == Self.basicUnlocKID {
                purchaseStatus = PurchaseStatus.basicUnlock.id
                return true
            }//: IF LET
        }//: LOOP (for await)
        return false
    }//: revertPurchaseToBasicUnlockStatus()
    
    private func revertPurchaseToLifetimeStatus() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement, transaction.productID == Self.proLifetimeID {
                purchaseStatus = PurchaseStatus.proLifetime.id
                return true
            }//: IF LET
        }//: LOOP (for await)
        return false
    }//: revertPurchaseToLifetimeStatus()
    
    private func revertPurchaseToFreeStatus() {
        purchaseStatus = PurchaseStatus.free.id
        currentSubscriptionType = ""
    }//:
    
    
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
    
    
    // MARK: - DOWNGRADING
    
    /*
     Downgrade Policy:
     > If a user chooses to downgrade from a paid option (Core or Pro) to a lower tier (Pro to Core, Pro to Free, or Core to Free),
        then only remove items that are copies on iCloud (as applicable) and extra credentials (which will subsequently remove all associated
        disciplinary actions, reinstatement actions, and renewal periods. Individual CE activities, however, will NOT be removed.)
     > Whatever items were created via the paid feature will be retained in CoreData or on the device (for media files) so that if the user
        chooses to upgrade again later, they won't lose any of their previously-created data.
     */
    
    

    func initiateDowngradeChanges(
        changeType: DowngradeType,
        selectedCred credential: Credential?
    ) async {
            switch changeType {
            case .noChange:
                return
            case .proToCore:
                if let credToKeep = credential {
                    await downgradeToCore(keepingCred: credToKeep)
                    await MainActor.run {
                        credentialSelectionNeeded = false
                    }//: MAIN ACTOR
                } else {
                    await downgradeToCore(keepingCred: nil)
                    await MainActor.run {
                        credentialSelectionNeeded = false
                    }//: MAIN ACTOR
                }//: IF LET (credToKeep)
            case .coreToFree:
                await downgradeToFree()
            case .proToFree:
                if let credToKeep = credential {
                    await downgradeToCore(keepingCred: credToKeep)
                    await downgradeToFree()
                    await MainActor.run {
                        credentialSelectionNeeded = false
                    }//: MAIN ACTOR
                } else {
                    await downgradeToCore(keepingCred: nil)
                    await downgradeToFree()
                    await MainActor.run {
                        credentialSelectionNeeded = false
                    }//: MAIN ACTOR
                }//: IF LET (credToKeep)
            }//: SWITCH
        // Once the downgrade methods have completed, reset the @Published properties
        await MainActor.run {
            downgradeMade = .noChange
        }//: MAIN ACTOR
    }//: initiateDowngradeChanges()
    
    
    private func downgradeToCore(keepingCred: Credential?) async {
        // Delete all credentials except for the one chosen by the user
        let allCreds = getAllCredentials()
        if allCreds.count > 1, let selectedCred = keepingCred {
            deleteAllCredsExceptFor(credToKeep: selectedCred)
        }//: IF (allCreds.count > 1)
        
        // Delete all audio reflections on iCloud
        // Keeping local copies on one device for restoration by user later if
        // they choose to upgrade to Pro again
        let mediaBrain = CloudMediaBrain.shared
        let _ = await mediaBrain.deleteAllAudioFiles()
        
        // Remove all certificates on iCloud NOT belonging to the current renewal (so long as under 500MB limit)
        let certsOutsideLimit = areThereUploadedCertsOutsideCurrentRenewal()
        if certsOutsideLimit.certsOutside {
            await mediaBrain.removeUploadedCerts(certs: certsOutsideLimit.certs)
        }//: IF (certsOutsideLimit)
    }//: downgradeToCore
    
    
    private func downgradeToFree() async {
        // Everyting in downgradeToCore, PLUS:
        // Remove ALL certificates from iCloud
        let mediaBrain = CloudMediaBrain.shared
        _ = await mediaBrain.deleteAllCertificateFilesOffICloud()
    }//: downgradeFromCoreToFree()
    
    
    
    
   
    
    
}//: DATA CONTROLLER

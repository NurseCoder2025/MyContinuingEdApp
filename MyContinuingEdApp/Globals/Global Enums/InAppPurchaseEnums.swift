//
//  InAppPurchaseEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import Foundation


// MARK: - In App Purchases

/// Enum for indicating whether the user has made an in-app purchase, and if so, which one, or
/// is using the free version of the app.
///
/// This enum has a computed id property that returns a String value for use as a value in the
/// sharedSettings key "purchaseStatus".  Those values are as follows:
///  - .free: "free"
///  - .basicUnlock: "basicUnlock"
///  - .proSubscription: "proSubscription"
///
///  - Note: Protocol conformance for this enum includes Codable & Identifiable.
enum PurchaseStatus: Codable, Identifiable {
    case free, basicUnlock, proSubscription, proLifetime
    
    // Identifiable conformance
    // Needed so that this enum can be used for presenting sheets
    // as an item
    var id: String {
        switch self {
        case .free: return "free"
        case .basicUnlock: return "basicUnlock"
        case .proSubscription: return "proSubscription"
        case .proLifetime: return "proLifetime"
        }//: SWITCH
    }//: id
}//: PURHCASE STATUS

/// Enum for indicating that the user has exceeded a pre-determined limit of objects while the
/// app is in free mode. This is an error type that is thrown by the DataController's createNewTag,
///  createNewRenewal, and createNewCeActivity methods.
enum UpgradeNeeded: Error {
    case maxTagsReached
    case maxRenewalsReached
    case maxCeActivitiesReached
}//: UpgradeNeeded

/// Enum for controlling what is shown to the user in the UpgradeToPaid sheet, depending on
/// whether the products from that AppStore have been loaded or if an erro has been thrown.
enum LoadState {
    case loading, loaded, error
}//: LoadState

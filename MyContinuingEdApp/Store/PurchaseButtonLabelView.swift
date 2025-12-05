//
//  PurchaseButtonLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/4/25.
//

import StoreKit
import SwiftUI

/// Label view that returns either a single line of text with the regular purchase price of the product or
/// any intro pricing if the user is eligible along with a special intro pricing header and description below
/// the main line.
/// - Parameters:
///       - product: generic object that can be either a Product or MockProduct (for previewing purposes)
struct PurchaseButtonLabelView<T: StorePreviewProtocol>: View {
    // MARK: - PROPERTIES
    let product: T
    
    @State private var productIsSubscription: Bool = false
    @State private var introEligible: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    /// Computed property that determines whether the product argument represents an actual
    /// Product data type or the MockProduct type
    var asProduct: Product? {
        product as? Product
    }
    
    /// Computed property that returns either the special introductory price for first-time subscribers or the regular price for use
    /// in the main body of the label for the purchase button in AppUpgradeCardView
    var mainLabelText: String {
        if let appProd = asProduct, let appSubscription = appProd.subscription, introEligible {
            let introPrice = appSubscription.introductoryOffer?.displayPrice ?? "0.00"
            let subscriptionTime = appSubscription.subscriptionPeriod.unit.localizedDescription
            return "\(introPrice) / \(subscriptionTime)"
        } else if let appProd = asProduct, let appSubscription = appProd.subscription {
            let subscriptionTime = appSubscription.subscriptionPeriod.unit.localizedDescription
            return "\(appProd.displayPrice) / \(subscriptionTime)"
        } else if let appProd = asProduct {
            return "Buy for \(appProd.displayPrice)"
        } else {
            return "Purchase for \(product.displayPrice)"
        }
    }//: mainLabelText
    
    /// Computed property that returns a more detailed string for users eligible for the introductory subscription by
    /// spelling out the terms of the intro pricing and then what the regular price will be after that
    var promoOfferText: String {
        if let appProd = asProduct, let appSubscription = appProd.subscription, introEligible {
            let introPrice = appSubscription.introductoryOffer?.displayPrice ?? "0.00"
            let subscriptionTime = appSubscription.subscriptionPeriod.unit.localizedDescription
            return "\(introPrice) for \(subscriptionTime), then \(appProd.displayPrice) each renewal thereafter"
        } else {
            return ""
        }
    }//: promoOfferText
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // New Subscriber Discount Header
            if introEligible {
                Text("New Subscriber Offer:")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)
            }
            
            // Main label text ( $0.00 / year - month - one time)
            Text(mainLabelText)
                .foregroundStyle(.white)
            
            // Discount/promo info
            if introEligible {
                Text(promoOfferText)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }//: VSTACK
        // MARK: - TASK
        .task {
            if let appProd = asProduct {
                guard appProd.subscription != nil else {return}
                productIsSubscription = true
                introEligible = await appProd.subscription?.isEligibleForIntroOffer ?? false
            }
        }//: TASK
    }//: BODY
   
    
}//: PurchaseButtonLabelView

// MARK: - PREVIEW
#Preview {
    let sampleProd = MockProduct(
        id: "sample.Prod.id",
        displayName: "Basic Unlock",
        description: "Essential features for tracking CEs for just one credential",
        price: 14.99,
        displayPrice: "$14.99"
    )
    
    PurchaseButtonLabelView(product: sampleProd)
}

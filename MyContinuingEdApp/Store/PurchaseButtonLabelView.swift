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
            // Regular subscription pricing
            let subscriptionTime = appSubscription.subscriptionPeriod.unit.localizedDescription.localizedLowercase
            let regSubPrice = appProd.displayPrice
            
            if let introOffer = appSubscription.introductoryOffer {
                let introType = introOffer.paymentMode
                let introDuration = introOffer.periodCount
                let introPrice = introOffer.displayPrice
                let introLength = introOffer.period.value
                let introLengthText = introOffer.period.unit.localizedDescription.localizedLowercase
                let pluralLengthText = NSLocalizedString(introLengthText, value: "month", comment: "plural version of the noun month")
                let offerString = (introType == .payUpFront ? "\(introLength) \(pluralLengthText) for \(introPrice)" : "\(introPrice)/\(introLengthText) for the first \(introDuration) \(pluralLengthText)")
                
                return offerString
            } else {
                return "Subscribe for \(regSubPrice) / \(subscriptionTime)"
            }
        } else if let appProd = asProduct, let appSubscription = appProd.subscription {
            let subscriptionTime = appSubscription.subscriptionPeriod.unit.localizedDescription.localizedLowercase
            let regSubPrice = appProd.displayPrice
            return "Subscribe for \(regSubPrice) / \(subscriptionTime)"
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
            let subTime = appSubscription.subscriptionPeriod.unit.localizedDescription.localizedLowercase
            let regPrice = appProd.displayPrice
            if let introOffer = appSubscription.introductoryOffer {
                let introType = introOffer.paymentMode
                let introDuration = introOffer.periodCount
                let introPrice = introOffer.displayPrice
                let introLength = introOffer.period.value
                let introLengthText = introOffer.period.unit.localizedDescription.localizedLowercase
                let pluralLengthText = NSLocalizedString(introLengthText, value: "month", comment: "plural version of the noun month")
                let offerString = (introType == .payUpFront ? "\(introLength) \(pluralLengthText) for \(introPrice), then \(regPrice) per \(subTime) thereafter." : "\(introDuration) \(pluralLengthText) at \(introPrice), then \(regPrice) per \(subTime) thereafter.")
                
                return offerString
            } else {
                return ""
            }
        } else {
            return ""
        }
    }//: promoOfferText
    
    // MARK: - BODY
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(product.id == DataController.basicUnlocKID ? basicGradient : proGradient)
                    .frame(height: 45)
                    .padding([.leading, .trailing], 20)
                    .accessibilityHidden(true)
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
                    
                    
                }//: VSTACK
                .frame(height: 45)
            }//: ZSTACK
            .padding(.top, 15)
            
            // Discount/promo info
            if introEligible {
                Text(promoOfferText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

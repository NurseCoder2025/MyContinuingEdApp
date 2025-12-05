//
//  AppUpgradeCardView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import StoreKit
import SwiftUI

struct AppUpgradeCardView<T: StorePreviewProtocol>: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    let product: T

    let cardHeight: CGFloat
    let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    // MARK: - CLOSURES
    // Because this is a child view, passing up button functions to the parent view for
    // improved UI stability
    let onLearnMore: (String) -> Void
    let onPurchase: (Product) -> Void
    let redeemCode: () -> Void
    let restorePurchases: () -> Void
    
    // MARK: - COMPUTED PROPERTIES
    
    var purchaseDescription: String {
        switch product.id {
            case DataController.basicUnlocKID:
            return "One-time Purchase"
        case DataController.proMonthlyID:
            return "Monthly Subscription"
        case DataController.proAnnualID:
            return "Annual Subscription"
        default:
            return "Unknown"
        }
    }//: purchaseDescription
    
    var asProduct: Product? {
        return product as? Product
    }
    
    // MARK: - BODY
    var body: some View {
        ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                    .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                    // MARK: - HEADER
                    HStack {
                        Text(product.displayName)
                            .font(.title3)
                            .bold()
                            .overlay(
                                product.id == DataController.basicUnlocKID ? basicGradient : proGradient
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .mask(
                                Text(product.displayName)
                                    .font(.title3)
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                            )
                            .padding([.leading, .top], 10)
                        Spacer()
                        Text(product.displayPrice)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 20)
                    }//: HSTACK
                    
                        Text(product.description)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 10)
                            .padding(.bottom, 20)
                            .fixedSize(horizontal: false, vertical: true)
                    
                
                     // MARK: - Features (Grid)
                if product.id == DataController.basicUnlocKID {
                        BasicFeaturesGridView()
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                    } else {
                        ProFeaturesGridView()
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                    }
                    
                    // MARK: - Footer
                    Spacer()
                    HStack {
                        Text(purchaseDescription)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                        Spacer()
                        // MARK: ON LEARN MORE
                        Button {
                            onLearnMore(product.id)
                        } label: {
                            Text("Learn More")
                        }//: BUTTON
                        .buttonStyle(.bordered)
                        Spacer()
                    }//: HSTACK
                
                // MARK: - PURCHASE Button
                Group {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(product.id == DataController.basicUnlocKID ? basicGradient : proGradient)
                            .frame(height: 45)
                            .padding([.leading, .trailing], 20)
                            .accessibilityHidden(true)
                        HStack {
                            Spacer()
                            Button {
                                if let appProd = asProduct {
                                    onPurchase(appProd)
                                }
                            } label: {
                                PurchaseButtonLabelView(product: product)
                            }
                            Spacer()
                        }//: HSTACK
                    }//: ZSTACK
                    .padding(.top, 15)
                }//: GROUP
                // MARK: - Codes & Restore Purchase
                HStack {
                    Spacer()
                    Button {
                        redeemCode()
                    } label: {
                        Text("Redeem Code")
                    }//: BUTTON
                    
                    Text("|")
                        .accessibilityHidden(true)
                    
                    Button {
                        restorePurchases()
                    } label: {
                        Text("Restore Purchases")
                    }//: BUTTON
                    Spacer()
                }//: HStack
                .padding(.top, 10)
                    Spacer()
                    
                }//: VSTACK
        }//: ZSTACK
        .frame(maxWidth: 350)
        .padding()
        
    }//: BODY
    
    // MARK: - CUSTOM INIT
    init(
        product: T,
        cardHeight: CGFloat,
        onLearnMore: @escaping (String) -> Void,
        onPurchase: @escaping (Product) -> Void,
        redeemCode: @escaping () -> Void,
        restorePurchases: @escaping () -> Void
    )
    {
        self.product = product
        self.cardHeight = cardHeight
        self.onLearnMore = onLearnMore
        self.onPurchase = onPurchase
        self.redeemCode = redeemCode
        self.restorePurchases = restorePurchases
    }
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    let basicProduct = MockProduct(
        id: "com.example.myapp.basic",
        displayName: "Basic Feature Unlock",
        description: "Essential features for tracking CEs for one credential.",
        price: 14.99,
        displayPrice: "$14.99"
        
    )
    AppUpgradeCardView(
        product: basicProduct,
        cardHeight: 2.5,
        onLearnMore: {_ in},
        onPurchase: {_ in},
        redeemCode: {},
        restorePurchases: {}
    )
    
}

#Preview {
    let annualProduct = MockProduct(
        id: "mock.annualProduct.id",
        displayName: "Pro Annual",
        description: "All the features in Basic Unlock PLUS",
        price: 24.99,
        displayPrice: "$24.99"
    )
    
    AppUpgradeCardView(
        product: annualProduct,
        cardHeight: 2,
        onLearnMore: {_ in },
        onPurchase: {_ in},
        redeemCode: {},
        restorePurchases: {}
    )
    
}

#Preview {
    let monthlyProduct = MockProduct(
        id: "mock.monthlyProduct.id",
        displayName: "Pro Monthly",
        description: "All pro features on a monthly subscription basis",
        price: 2.99,
        displayPrice: "$2.99"
    )
    
    AppUpgradeCardView(
        product: monthlyProduct,
        cardHeight: 2,
        onLearnMore: {_ in},
        onPurchase: {_ in},
        redeemCode: {},
        restorePurchases: {}
    )
}

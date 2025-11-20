//
//  AppUpgradeCardView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct AppUpgradeCardView: View {
    // MARK: - PROPERTIES
    let purchaseType: PurchaseStatus
    
    let headerText: String
    let briefDescription: String?
    let purchasePrice: Double
    let purchaseDescription: String
    
    let cardHeight: CGFloat
    
    let proGradient = LinearGradient(
        colors: [Color.purple, Color.red],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    let basicGradient = LinearGradient(
        colors: [Color.blue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    // MARK: - COMPUTED PROPERTIES
    var priceDisplayString: String {
        String(format: "$%.2f", purchasePrice)
    }//: priceDisplayString
    
    
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
                        Text(headerText)
                            .font(.title3)
                            .bold()
                            .overlay(
                                purchaseType == .proSubscription ? proGradient : basicGradient
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .mask(
                                Text(headerText)
                                    .font(.title3)
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                            )
                            .padding([.leading, .top], 10)
                        Spacer()
                        Text(priceDisplayString)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 20)
                    }//: HSTACK
                    if let description = briefDescription {
                        Text(description)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 10)
                            .padding(.bottom, 20)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                     // MARK: - Features (Grid)
                    if purchaseType == .basicUnlock {
                        BasicFeaturesGridView()
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                    } else if purchaseType == .proSubscription {
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
                        Button {
                            // TODO: Add action(s)
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
                            .foregroundStyle(purchaseType == .basicUnlock ? basicGradient : proGradient)
                            .frame(height: 45)
                            .padding([.leading, .trailing], 20)
                            .accessibilityHidden(true)
                        HStack {
                            Spacer()
                            Button {
                                // TODO: Add action(s)
                            } label: {
                                Text("\(purchaseType == .basicUnlock ? "Buy" : "Subscribe") for \(priceDisplayString)")
                                    .foregroundStyle(.white)
                                    .bold()
                            }//: BUTTON
                            Spacer()
                        }//: HSTACK
                    }//: ZSTACK
                    .padding(.top, 15)
                }//: GROUP
                
                
                    Spacer()
                    
                }//: VSTACK
        }//: ZSTACK
        .frame(maxWidth: 350)
        .padding()
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    AppUpgradeCardView(
        purchaseType: .basicUnlock,
        headerText: "Basic Feature Unlock",
        briefDescription: "Essential features for tracking CEs for one credential",
        purchasePrice: 14.99,
        purchaseDescription: "One time purchase",
        cardHeight: 2.5
    )
    
}

#Preview {
    AppUpgradeCardView(
        purchaseType: .proSubscription,
        headerText: "CE Cache Pro Subscription",
        briefDescription: "Everything in the basic feature unlock PLUS:",
        purchasePrice: 24.99,
        purchaseDescription: "Annual Subscription",
        cardHeight: 2
    )
    
}

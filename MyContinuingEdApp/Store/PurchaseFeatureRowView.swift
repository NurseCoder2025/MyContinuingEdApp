//
//  PurchaseFeatureRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct PurchaseFeatureRowView: View {
    // MARK: - PROPERTIES
    let purchaseType: PurchaseStatus
    
    let featureIcon: String
    let featureText: String
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Image(systemName: featureIcon)
                .foregroundStyle(
                    purchaseType == .proSubscription ? .purple : .blue)
            Text(featureText)
                .bold()
        }//: HSTACK
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    PurchaseFeatureRowView(purchaseType: .basicUnlock, featureIcon: "tag.fill", featureText: "Unlimited tags")
}

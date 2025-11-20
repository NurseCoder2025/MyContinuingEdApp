//
//  FeaturesDetailsHeaderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct FeaturesDetailsHeaderView: View {
    // MARK: - PROPERTIES
    let upgradeType: PurchaseStatus
    
    let basicGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .topTrailing
    )
    
    let proGradient = LinearGradient(
        colors: [Color.red.opacity(0.6), Color.purple.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .topTrailing
    )
    
    // MARK: - BODY
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(upgradeType == .basicUnlock ? basicGradient : proGradient)
                    .frame(width: 350, height: 75)
                    .shadow(radius: 4)
                    .accessibilityHidden(true)
                
                Text(upgradeType == .basicUnlock ? "Basic Feature Unlock" : "Pro Subscription")
                    .font(.title)
                    .foregroundStyle(.white)
                    .bold()
                
            }//: ZSTACK
            .frame(width: 350, height: 100)
            
            Text(upgradeType == .basicUnlock ? "Essential features to track CE hours for a single credential." : "Everything included with the basic feature unlock, PLUS much more...")
                .padding([.leading, .trailing], 20)
                .foregroundStyle(.secondary)
        }//: VSTACK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    FeaturesDetailsHeaderView(upgradeType: .basicUnlock)
}

#Preview {
    FeaturesDetailsHeaderView(upgradeType: .proSubscription)
}

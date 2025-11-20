//
//  FeaturesDetailsRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct FeaturesDetailsRowView: View {
    // MARK: - PROPERTIES
    let feature: UpgradeFeature
    let upgradeType: PurchaseStatus
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
                .frame(maxWidth: 330, maxHeight: 300)
                .accessibilityHidden(true)
            HStack(alignment: .center) {
                Image(systemName: feature.featureIcon)
                    .font(.largeTitle)
                    .foregroundStyle(upgradeType == .basicUnlock ? .blue : .purple)
                    .padding([.leading, .trailing], 20)
             
                VStack(alignment: .leading, spacing: 0) {
                    Text(feature.featureText)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.title3)
                        .foregroundStyle(upgradeType == .basicUnlock ? .blue : .purple)
                        .padding(.bottom, 5)
                        .padding(.top, 10)
                    
                    Text(feature.sellingPoint)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 15)
                }//: VSTACK
                Spacer()
            }//: HSTACK
            .accessibilityLabel(Text(feature.featureText))
            .accessibilityHint(Text(feature.sellingPoint))
        }//: ZSTACK
        .frame(maxWidth: 330, maxHeight: 330)
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    FeaturesDetailsRowView(feature: .example, upgradeType: .basicUnlock)
}

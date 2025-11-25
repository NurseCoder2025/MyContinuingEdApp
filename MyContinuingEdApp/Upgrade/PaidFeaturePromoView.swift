//
//  PaidFeaturePromoView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/20/25.
//

import SwiftUI

struct PaidFeaturePromoView: View {
    // MARK: - PROPERTIES
    let featureIcon: String
    let featureItem: String
    let featureUpgradeLevel: FeatureAvailability
    
    enum FeatureAvailability: String, CaseIterable {
        case basicAndPro = "either the Pro subscription or basic feature unlock"
        case ProOnly = "the Pro subscription only"
    }
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color(.systemGray6))
                .frame(height: 100)
                .accessibilityHidden(true)
            
            HStack {
                Image(systemName: featureIcon)
                    .font(.largeTitle)
                    .foregroundStyle(Color(.gray))
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading) {
                    Text("\(featureUpgradeLevel == .basicAndPro ? "Paid" : "Pro") Feature:")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .bold()
                    Text(featureItem)
                        .foregroundStyle(.secondary)
                        .bold()
                    Text("Unlock by purchasing \(featureUpgradeLevel.rawValue)")
                        .font(.caption)
                        .padding(.trailing, 25)
                }//: VSTACK
                
            }//: HSTACK
            .padding(.leading, 10)
            .accessibilityLabel(Text("Paid feature: \(featureItem)"))
            .accessibilityHint("Unlock by purchasing \(featureUpgradeLevel.rawValue)")
            
        }//: ZSTACK
        .frame(height: 100)
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    PaidFeaturePromoView(featureIcon: "pencil.and.scribble", featureItem: "Activity Reflection", featureUpgradeLevel: .basicAndPro)
}

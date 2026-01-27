//
//  PaidFeaturePromoView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/20/25.
//

import SwiftUI

/// Template view used to highlight features that are only accessible at a certain app purchase level.
///
/// - Parameters:
///     - featureIcon: String for a SF symbol compatible with versions of iOS 17 & later
///     - oldiOSIcon: String for a SF symbol compatible with iOS 16 and earlier ONLY (OPTIONAL)
///     - featureItem: String for the name of the feature being highlighted
///     - featureUpgradeLevel: FeatureAvailability enum value (basicAndPro, ProOnly)
struct PaidFeaturePromoView: View {
    // MARK: - PROPERTIES
    let featureIcon: String
    var oldiOSIcon: String? = nil
    
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
                if let oldIcon = oldiOSIcon {
                    Image(systemName: oldIcon)
                        .font(.largeTitle)
                        .foregroundStyle(Color(.gray))
                        .padding(.trailing, 10)
                } else {
                    Image(systemName: featureIcon)
                        .font(.largeTitle)
                        .foregroundStyle(Color(.gray))
                        .padding(.trailing, 10)
                }//: IF LET
                
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

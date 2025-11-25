//
//  ProFeaturesGridView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import SwiftUI

struct ProFeaturesGridView: View {
    // MARK: - PROPERTIES
    
    let columns = Array(repeating: GridItem(.adaptive(minimum: 120), alignment: .leading), count: 2)
    
    
    // MARK: - BODY
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(proFeatures) { feature in
                PurchaseFeatureRowView(
                    purchaseType: .proSubscription,
                    featureIcon: feature.altIcon ?? feature.featureIcon,
                    featureText: feature.featureText
                )
            }//: LOOP
        }//: GRID
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ProFeaturesGridView()
}

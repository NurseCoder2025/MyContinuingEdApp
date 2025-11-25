//
//  UpgradeItem.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import Foundation


struct UpgradeFeature: Identifiable {
    let id: UUID = UUID()
    
    let featureIcon: String
    // The altIcon is intended to supply the name of an SF symbol that is available to
    // older versions of iOS (16 or earlier) in case the featureIcon is only available
    // in newer iOS versions.
    let altIcon: String?
    let featureText: String
    let sellingPoint: String
    
    // MARK: - SAMPLE Item
    
    static let example = UpgradeFeature(
        featureIcon: "bag.fill",
        featureText: "Test Feature",
        sellingPoint: "Test Selling Point"
    )
    // MARK: - CUSTOM INITs
    
    init(featureIcon: String, altIcon: String?, featureText: String, sellingPoint: String) {
        self.featureIcon = featureIcon
        self.altIcon = altIcon
        self.featureText = featureText
        self.sellingPoint = sellingPoint
    }
    
    init(featureIcon: String, featureText: String, sellingPoint: String) {
        self.featureIcon = featureIcon
        self.altIcon = nil
        self.featureText = featureText
        self.sellingPoint = sellingPoint
    }
}//: UpgradeItem

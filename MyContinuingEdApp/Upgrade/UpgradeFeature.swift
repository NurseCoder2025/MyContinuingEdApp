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
    let featureText: String
    let sellingPoint: String
    
    // MARK: - SAMPLE Item
    
    static let example = UpgradeFeature(
        featureIcon: "bag.fill",
        featureText: "Test Feature",
        sellingPoint: "Test Selling Point"
    )
    
}//: UpgradeItem

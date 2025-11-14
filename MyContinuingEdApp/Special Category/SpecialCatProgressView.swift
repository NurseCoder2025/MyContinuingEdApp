//
//  SpecialCatProgressView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/13/25.
//

import SwiftUI

struct SpecialCatProgressView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    let renewal: RenewalPeriod
    let specialCat: SpecialCategory
    
    // for customizing the color of the progress bar for multiple special categories
    let color: String
    
    // MARK: - COMPUTED PROPERTIES
    var specialCatName: String {specialCat.specialName}
    
    var totalSpecialCatCEsEarned: Double {
        var earned: Double = 0.0
        let results = dataController.calculateSpecialCECatHoursEarnedFor(renewal: renewal)
        if let value = results.first(where: {$0.key == specialCat})?.value {
            earned = value
        }
        return earned
    }
    
    var totalSpecialCatHoursRequired: Double {specialCat.requiredHours}
    
    var getCEMeasurement: String {
        if let renewalCred = renewal.credential {
            if renewalCred.measurementDefault == 1 {
                return "hours"
            } else {
                return "units"
            }
        } else {
            return ""
        }
    }
    
    
    // MARK: - BODY
    var body: some View {
        ProgressView(
                    "CE \(getCEMeasurement) earned for \(specialCatName)",
                     value: totalSpecialCatCEsEarned,
                     total: totalSpecialCatHoursRequired
        )
        .progressViewStyle(.linear)
        .foregroundStyle(Color(color))
        
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    SpecialCatProgressView(renewal: .example, specialCat: .example, color: "blue")
}

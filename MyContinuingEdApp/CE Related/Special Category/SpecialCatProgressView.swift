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
    let color: String?
    
    // MARK: - COMPUTED PROPERTIES
    var specialCatName: String {specialCat.specialName}
    
    /// Computed property that returns a Double representing the number of CEs earned for a specific
    /// SpecialCategory object (whichever one was passed into the SpecialCatProgressView struct). If the
    /// Credential to which the SpecialCategory was assigned measures CEs in units vs hours, then the
    /// CEs earned value is converted into units.
    var totalSpecialCatCEsEarned: Double {
        var earned: Double = 0.0
        let results = dataController.calculateCeEarnedForSpecialCatsIn(renewal: renewal)
        if let value = results.first(where: {$0.key == specialCat})?.value {
            earned = value
        }
        // Conveting results to units if the Credential measures CEs in units vs
        // clock hours
        if let renewalCred = renewal.credential {
            if renewalCred.measurementDefault == 2 {
                let convertedHours = dataController.convertHoursToUnits(earned, for: renewal)
                return convertedHours
            } else {
                return earned
            }
        } else {
            return earned
        }//: IF LET
    }//: totalSpecialCatCEsEarned
    
    var totalSpecialCatHoursRequired: Double {specialCat.requiredHours}
    
    var percentageEarnedString: String {
        let percentEarned = ((totalSpecialCatCEsEarned / totalSpecialCatHoursRequired) * 100)
        return String(format: "%.0f", percentEarned)
    }
    
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
        HStack(spacing: 0) {
            ProgressView(
                "CE \(getCEMeasurement) earned for \(specialCatName)",
                value: totalSpecialCatCEsEarned,
                total: totalSpecialCatHoursRequired
            )
            .progressViewStyle(.linear)
            .foregroundStyle(Color(color ?? "blue"))
            .accessibilityLabel(Text("CE \(getCEMeasurement) earned for \(specialCatName)"))
            .accessibilityHint(
                Text("So far in the \(renewal.renewalPeriodName), you have earned \(percentageEarnedString)% of the total required CEs for the \(specialCatName) requirement.")
            )
            
            Text(percentageEarnedString + "%")
                .font(.title3)
                .bold()
        }//: HSTACK
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    SpecialCatProgressView(renewal: .example, specialCat: .example, color: "blue")
}

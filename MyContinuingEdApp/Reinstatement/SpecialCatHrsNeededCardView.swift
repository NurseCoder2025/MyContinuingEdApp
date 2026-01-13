//
//  SpecialCatHrsNeededCardView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/12/26.
//

import SwiftUI

/// View that displays information in a card like fashion for any ReinstatementSpecialCat items
/// that the user still needs to complete (as determined by the DataController's
/// getOutstandingSpecialCatsForReinstatement method). This is a subview of
/// ReinstatementCEProgressView.
struct SpecialCatHrsNeededCardView: View {
    // MARK: - PROPERTIES
    let specCat: ReinstatementSpecialCat
    let hoursNeeded: Double
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property that returns the labelText property for the SpecialCategory object
    /// assigned to the ReinstatementSpecialCat object, which will either be the abbreviation
    /// of the SpecialCategory or the full name.
    var specCatName: String {
        if let category = specCat.specialCat {
            return category.labelText
        } else {
            return ""
        }
    }//: specCatName
    
    /// Computed property that converts the hoursNeeded argument into units if the associated
    /// Credential being reinstated measures CEs in terms of units vs hours. Otherwise, returns
    /// the hoursNeeded property.
    var convertedHours: Double {
        if let reinstatement = specCat.reinstatement, let renewal = reinstatement.renewal, let renewCred = renewal.credential {
            if renewCred.measurementDefault == 2 {
                let ratio = renewCred.defaultCesPerUnit
                return hoursNeeded / (ratio > 0 ? ratio : 10)
            } else {
                return hoursNeeded
            }
        } else {
            return hoursNeeded
        }
        
    }//: convertedHours
    
    /// Computed property that returns a string indicating whether the calculated number
    /// is in clock hours or units, depending upon the Credential being reinstated.
    var measurementString: String {
        if let reinstatement = specCat.reinstatement, let renewal = reinstatement.renewal, let renewCred = renewal.credential {
            if renewCred.measurementDefault == 2 {
                return "units"
            } else {
                return "hours"
            }
        } else {
            return "hours"
        }
    }//: measurementString
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text(specCatName)
                .bold()
            
            Text("\(convertedHours) \(measurementString.capitalized)")
            Text("Still Needed")
        }//: VSTACK
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8).border(Color(.secondarySystemBackground))
        )
        .accessibilityLabel(Text("\(measurementString) required for \(specCatName)"))
        .accessibilityHint(Text("You still need to complete \(convertedHours) \(measurementString)' worth of CE that are designated for \(specCatName) in order to meet all CE requirements for reinstatement. This amount is part of the overall total number of CEs that are required for reinstatement."))
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    SpecialCatHrsNeededCardView(
        specCat: .example,
        hoursNeeded: 5.0)
}

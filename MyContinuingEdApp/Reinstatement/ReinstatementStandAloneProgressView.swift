//
//  ReinstatementStandAloneProgressView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/12/26.
//

import SwiftUI

/// View that shows the user how much progress they've made towards completing the overall CE
/// requirement for reinstating a credential.  Displayed in two places in the app: first,
/// in the RenewalPeriodNavLabelView (when the conditions are met for showing it) and
/// in the ReinstatementCEProgressView, which is part of the ReinstatementInfoSheet.
///
/// The reason the requiredHours parameter is required is because the DataController's
/// calculateCEsForReinstatement method returns a tuple containing the latest value for the
/// ReinstatementInfo's totalExtraCEs property along with a calculated total of all CEs earned
/// that the user is applying towards credential reinstatement.
struct ReinstatementStandAloneProgressView: View {
    // MARK: - PROPERTIES
    
    let reinstatement: ReinstatementInfo
    let requiredHours: Double
    let earnedHours: Double
    
    // MARK: - COMPUTED PROPERTIES
    var reinstateRenewal: RenewalPeriod? {return reinstatement.renewal}
    
    var ceMeasurement: String {
        if let renewal = reinstatement.renewal, let renewCred = renewal.credential {
            if renewCred.measurementDefault == 1 {
                return "hours"
            } else {
                return "units"
            }
        } else {
            return "hours"
        }
    }//: ceMeasurement
    
    /// Computed property that either returns the requiredHours argument or converts it to units.
    ///
    /// If the Credential being reinstated measures CEs in units vs hours (as determined by the Credential
    /// measurementDefault property), then the CE value (which was calculated in hours) will be converted
    /// to units using the Credential's defaultCesPerUnit property (or 10 if that value is 0 or less).
    var cesRequired: Double {
        if let renewal = reinstatement.renewal, let renewCred = renewal.credential {
            // To avoid dividing by 0, adding this check on the hrsRequired to
            // avoid an undefined result and app crash
            guard requiredHours > 0 else { return 1.0 }
            
            if ceMeasurement == "units" {
                let cr = renewCred.defaultCesPerUnit  // cr = conversion ratio
                let convertedHrs: Double = requiredHours / (cr > 0 ? cr : 10.0)
                return convertedHrs
            } else {
                return requiredHours
            }
        } else {
            // To avoid dividing by zero, returning a 1.0 as a minimum value
            return 1.0
        }
    }//: cesRequired
    
    /// Computed property that returns either the earnedHours argument or converts it into units.
    ///
    /// Will convert CE value to units if the Credential being renewed measures CEs in terms of units instead of
    /// clock hours.  For this conversion, it uses the value of the Credential's defaultCesPerUnit value OR 10 if
    /// that value is not greater than 0.
    var cesEarned: Double {
        if let renewal = reinstateRenewal, let renewCred = renewal.credential {
            if ceMeasurement == "units" {
                let cr = renewCred.defaultCesPerUnit
                let convertedHrs: Double = earnedHours / (cr > 0 ? cr : 10.0)
                return convertedHrs
            } else {
                return earnedHours
            }
        } else {
            return 0.0
        }
    }//: cesEarned
    
    /// Computed property that calculates the percentage of total CEs earned and returns it formatted as a
    /// String using the String percent formatter method.
    var progressPercentage: String {
        let value = Int((cesEarned / cesRequired) * 100)
        return String(value.formatted(.percent))
    }//: progressPercentage
    
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 10) {
            ProgressView(
                "\(progressPercentage) Complete",
                value: cesEarned,
                total: cesRequired
            )
            .progressViewStyle(.linear)
            
            Text("\(String(format: "%.2f", cesEarned)) of \(String(format: "%.2f", cesRequired)) CE \(ceMeasurement.capitalized) Earned")
                .font(.caption)
                .foregroundStyle(.secondary)
            
        }//: VStack
        .padding(.horizontal, 10)
        .accessibilityLabel(Text("You've completed \(progressPercentage) of the required CEs to reinstate your credential thus far."))
        .accessibilityHint(Text("Specifically, you've earned \(cesEarned) \(ceMeasurement) out of the \(cesRequired) required."))
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ReinstatementStandAloneProgressView(
        reinstatement: .example,
        requiredHours: 5,
        earnedHours: 2.5
     )
}

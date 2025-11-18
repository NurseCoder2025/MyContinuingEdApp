//
//  RenewalProgressView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/13/25.
//

import SwiftUI

struct RenewalProgressView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    let renewal: RenewalPeriod
    
    // MARK: - COMPUTED PROPERTIES
    var totalCEsEarned: Double {
        let earned = dataController.calculateRenewalPeriodCEsEarned(renewal: renewal)
        let required = totalCEsRequired
        // Clamp earned between 0 and required
        return min(max(earned, 0), required)
    }
    
    var totalCEsRequired: Double {
        if let renewalCred = renewal.credential {
            // Ensure required is at least 1 to avoid division by zero and ProgressView errors
            return max(renewalCred.renewalCEsRequired, 1)
        } else {
            return 25.0
        }
    }
    
    var percentageEarnedString: String {
        let percentEarned = (totalCEsEarned / totalCEsRequired) * 100.0
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
        HStack(spacing: 5) {
            ProgressView(value: totalCEsEarned, total: totalCEsRequired)
            .frame(maxWidth: 150)
            .progressViewStyle(.linear)
            .tint(Color(.systemGreen))
            .accessibilityLabel(Text("Total CE \(getCEMeasurement) earned for the \(renewal.renewalPeriodName)"))
            .accessibilityHint(
                Text("So far in the \(renewal.renewalPeriodName), you've completed \(percentageEarnedString)% of the total CEs required. Keep up the good work!")
            )
            
            Text(percentageEarnedString + "%")
                .font(.title3)
                .bold()
        }//: HSTACK
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    RenewalProgressView(renewal: .example)
}

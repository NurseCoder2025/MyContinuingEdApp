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
        dataController.calculateRenewalPeriodCEsEarned(renewal: renewal)
    }
    
    var totalCEsRequired: Double {
        if let renewalCred = renewal.credential {
           return renewalCred.renewalCEsRequired
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
            ProgressView(value: totalCEsEarned, total: totalCEsRequired) {
                Text("CEs Earned (in \(getCEMeasurement))")
            }
            .progressViewStyle(.linear)
            .foregroundStyle(Color(.green))
            .accessibilityLabel(Text("Total CE \(getCEMeasurement) earned for the \(renewal.renewalPeriodName)"))
            .accessibilityHint(
                Text("So far in the \(renewal.renewalPeriodName), you've completed \(percentageEarnedString)% of the total CEs required. Keep up the good work!")
            )
            
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    RenewalProgressView(renewal: .example)
}

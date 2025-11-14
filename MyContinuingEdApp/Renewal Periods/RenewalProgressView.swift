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
            
    }//: BODY
    
    // MARK: - INIT
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    RenewalProgressView(renewal: .example)
}

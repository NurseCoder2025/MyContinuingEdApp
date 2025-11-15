//
//  RenewalPeriodNavLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import SwiftUI

struct RenewalPeriodNavLabelView: View {
    // MARK: - PROPERTIES
    let renewalFilter: Filter
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Label(renewalFilter.name, systemImage: "calendar.badge.clock")
            
            if let renewal = renewalFilter.renewalPeriod {
                RenewalProgressView(renewal: renewal)
            }
        }//: VSTACK
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    let sampleFilter = Filter(name: "Test", icon: "chart.bar.xaxis")
    RenewalPeriodNavLabelView(renewalFilter: sampleFilter)
}

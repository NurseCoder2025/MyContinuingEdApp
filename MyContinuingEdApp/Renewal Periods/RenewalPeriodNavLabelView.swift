//
//  RenewalPeriodNavLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import SwiftUI

struct RenewalPeriodNavLabelView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    let renewalFilter: Filter
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return .proSubscription
        case PurchaseStatus.basicUnlock.id:
            return .basicUnlock
        default:
            return .free
        }
    }//: paidStatus
    
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 2) {
            Label(renewalFilter.name, systemImage: "calendar.badge.clock")
            
            if let renewal = renewalFilter.renewalPeriod, paidStatus == .proSubscription {
                RenewalProgressView(renewal: renewal)
                    .padding(.leading, 23)
            }
        }//: VSTACK
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    let sampleFilter = Filter(name: "Test", icon: "chart.bar.xaxis")
    RenewalPeriodNavLabelView(renewalFilter: sampleFilter)
}

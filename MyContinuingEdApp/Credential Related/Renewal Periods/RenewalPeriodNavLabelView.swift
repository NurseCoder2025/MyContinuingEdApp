//
//  RenewalPeriodNavLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import SwiftUI

/// View that shows a progress bar (currently using Apple's ProgressView) indicating the percentage of CEs that the user has
/// completed for whatever renewal period has been passed into the parent view as an argument.
///
/// If the user is currently a Pro subscriber and also has a RenewalPeriod where they reinstated (or are currently reinstating)
/// a credential, then if they still need to complete those additional CEs then the progress bar will change to reflect that
/// by showing the ReinstatementStandAloneProgressView instead of the regular RenewalProgressView.
///
/// Upon loading of this view, the DataController method calculateCEsForReinstatement method is run, the returned tuple
/// then being used to update two @State properties (reinstateRequiredCes & reinstateEarnedCes) which will be passed
/// to the ReinstatementStandAloneProgressView as argurments.  It will also update the associated ReinstatementInfo's
/// cesCompletedYN property based on whether the number of earned total CEs and CEs for any required credential-specific
/// categories meet or exceed those that have been required.  If so, then only the normal RenewalProgressView will be
/// shown.
struct RenewalPeriodNavLabelView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @State private var reinstateRequiredCes: Double = 1.0
    @State private var reinstateEarnedCes: Double = 0.0
    
    let renewalFilter: Filter
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property that fetches what the current purchase status is for the app from the DataController's
    /// Published purchaseStatus property.  The returned value is the PurchaseStatus enum type.
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
                
                if let credReinstatement = renewal.reinstatement, credReinstatement.cesCompletedYN == false, credReinstatement.totalExtraCEs > 0 {
                    ReinstatementStandAloneProgressView(
                        reinstatement: credReinstatement,
                        requiredHours: reinstateRequiredCes,
                        earnedHours: reinstateEarnedCes
                    )
                    .padding(.leading, 23)
                } else {
                    RenewalProgressView(renewal: renewal)
                        .padding(.leading, 23)
                }
                
            }//: IF LET
            
        }//: VSTACK
        // MARK: - ON APPEAR
        .onAppear {
            if let renewal = renewalFilter.renewalPeriod {
                guard let _ = renewal.reinstatement else { return }
                let currentCes = dataController.calculateCEsForReinstatement(renewal: renewal)
                reinstateRequiredCes = currentCes.required
                reinstateEarnedCes = currentCes.earned
            }//: IF LET
            
        }//: ON APPEAR
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    let sampleFilter = Filter(name: "Test", icon: "chart.bar.xaxis")
    RenewalPeriodNavLabelView(renewalFilter: sampleFilter)
}

//
//  ActivityCEDetailsView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: To display the UI controls for the CE Details section of the parent
// view (ActivityView) in order to keep the code for that view manageable
// and reusable

import SwiftUI

struct ActivityCEDetailsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
   // MARK: - CLOSURES
    var showCEDesignationSheet: () -> Void
    var showSpecialCatSheet: () -> Void
    
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
        Group {
            // MARK: Designation
            Section("CE Details") {
                Button {
                    showCEDesignationSheet()
                } label: {
                    HStack {
                        Text("Designated as:")
                        if let des = activity.designation {
                            Text(des.ceDesignationAbbrev)
                                .lineLimit(1)
                        } else {
                            Text("Select")
                        }
                    }//: HSTACK
                } //: BUTTON
                
                // MARK: Special Category
                DisclosureGroup("Credential-Specific CEs") {
                if paidStatus != .proSubscription {
                    PaidFeaturePromoView(
                        featureIcon: "list.bullet.rectangle.fill",
                        featureItem: "Credential-Specific CE Categories",
                        featureUpgradeLevel: .ProOnly
                    )
                } else {
                        VStack(spacing: 10) {
                            Text("Required CE Category")
                                .bold()
                            Text("If the activity certificate indicates that the hours/units are for a specific kind of continuing education requirement by the governing body, such as law or ethics, indicate that here.")
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                            
                            Button {
                                showSpecialCatSheet()
                            } label: {
                                HStack {
                                    Text("Category:")
                                    if let assignedCat = activity.specialCat {
                                        Text(assignedCat.specialName)
                                            .lineLimit(1)
                                    } else {
                                        Text("Select")
                                    }
                                    Spacer()
                                }//: HStack
                            }//: BUTTON
                            .buttonStyle(.borderedProminent)
                        } //: VSTACK
                    
                    }//: IF ELSE
                }//: DISCLOSURE GROUP
                
                // MARK: Apply CEs towards Credential Reinstatement
                DisclosureGroup("Credential Reinstatement") {
                if paidStatus != .proSubscription {
                    PaidFeaturePromoView(
                        featureIcon: "graduationcap.fill",
                        featureItem: "Remedial CE",
                        featureUpgradeLevel: .ProOnly
                    )
                } else {
                        VStack {
                            Text("Apply the CEs from this activity towards the reinstatement of a credential?")
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                            Toggle("Reinstatement CE?", isOn: $activity.forReinstatementYN)
                        }//: VSTACK
                    }//: IF ELSE
                }//: DISCLOSURE GROUP
                
            }//: SECTION
        }//: GROUP
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityCEDetailsView(
        activity: .example,
        showCEDesignationSheet: {},
        showSpecialCatSheet: {}
    )
}

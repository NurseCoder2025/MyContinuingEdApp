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
    
    // Bindings to parent view (ActivityView)
    @State private var showCeDesignationSheet: Bool = false
    @State private var showSpecialCECatAssignmentSheet: Bool = false
    
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
                    showCeDesignationSheet = true
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
                
                if paidStatus != .proSubscription {
                    PaidFeaturePromoView(
                        featureIcon: "list.bullet.rectangle.fill",
                        featureItem: "Credential-Specific CE Categories",
                        featureUpgradeLevel: .ProOnly
                    )
                } else {
                    // MARK: Special Category
                    VStack {
                        Text("Special CE Category:")
                            .bold()
                        Text("NOTE: If the activity certificate indicates that the hours/units are for a specific kind of continuing education requirement by the governing body, such as law or ethics, indicate that here.")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                        
                        Button {
                            showSpecialCECatAssignmentSheet = true
                        } label: {
                            HStack {
                                Text("Category:")
                                if let assignedCat = activity.specialCat {
                                    Text(assignedCat.specialName)
                                        .lineLimit(1)
                                } else {
                                    Text("Select Category (if applicable)")
                                }
                            }//: HSTACK
                        }
                        
                    } //: VSTACK
                }//: IF ELSE
                
            }//: SECTION
        }//: GROUP
        // MARK: - SHEETS
        // CeDesgination selection (i.e. CME, legal CE, etc.)
        .sheet(isPresented: $showCeDesignationSheet) {
                CeDesignationSelectionSheet(activity: activity)
        }//: SHEET (CE Designation)
        
        // CE Category selection
        .sheet(isPresented: $showSpecialCECatAssignmentSheet) {
            SpecialCECatsManagementSheet(dataController: dataController, activity: activity)
        }//: SHEET (SpecialCECatASsignmentManagementSheet)
                
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityCEDetailsView(activity: .example)
}

//
//  RenewalPeriodEditingView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: Draw the controls for the user to be able to create and edit RenewalPeriod objects

import SwiftUI

struct RenewalTopEditingView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    // Using a LET constant instead of ObservableObject because
    // this view only needs to read Credential object properties.
    let credential: Credential
    
    // Bindings to parent view (RenewalPeriodView)
    @Binding var reinstatingYN: Bool
    @Binding var reinstateHours: Double
    
    // MARK: - CLOSURES
    var toggleHelp: () -> Void
    
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
    
    var credCEMeasurement: String {
        switch credential.measurementDefault {
        case 1:
            return "hours"
        default:
            return "units"
        }
    }//: credCEMeasurement
    
    // MARK: - BODY
    var body: some View {
        Group {
            VStack {
                // Name of specified credential
                HStack {
                    Text("For Credential:")
                    Text(credential.credentialName)
                        .bold()
                        .foregroundStyle(.yellow)
                }//: HSTACK
                .font(.title2)
                
                
                if paidStatus != .proSubscription {
                    PaidFeaturePromoView(
                        featureIcon: "graduationcap.fill",
                        featureItem: "Remedial CE Hours",
                        featureUpgradeLevel: .ProOnly
                    )
                } else {
                    // Reinstatement info
                    HStack {
                        Toggle(isOn: $reinstatingYN) {
                            Text("Reinstating Credential?")
                        }
                        .padding([.leading, .trailing], 30)
                        
                        Button {
                            toggleHelp()
                        } label: {
                            Label("More Info", systemImage: "questionmark.circle.fill")
                        }//: BUTTON
                    }//: HSTACK
                    if reinstatingYN {
                        VStack(spacing: 10) {
                            HStack {
                                Text("CE \(credCEMeasurement.uppercased()) Required:")
                                    .bold()
                                TextField("CE \(credCEMeasurement.uppercased()) Needed:",
                                          value: $reinstateHours,
                                          formatter: twoDigitDecimalFormatter
                                )
                            }//: HSTACK
                            .padding(.leading, 30)
                            
                            Text("If your licensing board requires additional \(credCEMeasurement) to renew on top of the normal amount, please enter the extra number of \(credCEMeasurement) you need to complete for this renewal period.")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                        }//: VSTACK
                    }//: IF
                }//: IF ELSE
                
            }//: VSTACK
            .padding()
            
        }//: GROUP
        // MARK: - SHEETS
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RenewalTopEditingView(
        credential: .example,
        reinstatingYN: .constant(true),
        reinstateHours: .constant(1.0),
        toggleHelp: {}
    )
        .environmentObject(DataController.preview)
}

//
//  TotalRenewalProgressBar.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/17/25.
//

import SwiftUI

struct TotalRenewalProgressBar: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    let renewal: RenewalPeriod
    
    // MARK: - COMPUTED PROPERTIES
    var totalCEsEarned: Double {
        let earned = dataController.calculateRenewalPeriodCEsEarned(renewal: renewal)
        let required = totalCEsRequired
        
        if let renewalCred = renewal.credential {
            if renewalCred.measurementDefault == 2 {
               let earnedConverted = dataController.convertHoursToUnits(earned, for: renewal)
               return min(max(earnedConverted, 0), required)
            }
        }
        // Clamp earned between 0 and required
        return min(max(earned, 0), required)
    }//: totalCEsEarned
    
    var totalCEsRequired: Double {
        if let renewalCred = renewal.credential {
            return max(renewalCred.renewalCEsRequired, 1)
        } else {
            return 25.0
        }
    }//: totalCEsRequired
    
    var totalProgress: CGFloat {
        CGFloat(totalCEsEarned / totalCEsRequired)
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
        VStack {
            GeometryReader {geo in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 25)
                        .foregroundStyle(Color(.systemGray4))
                        .shadow(radius: 2)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .frame(
                            width: totalProgress * geo.size.width,
                            height: 25
                        )
                        .foregroundStyle(Color(.systemBlue))
                    
                    // Only showing the percentage in a text box if the
                    // progress bar is long enough to contain it
                    if totalProgress * geo.size.width >= 50 {
                        HStack {
                            Spacer()
                            Text("\(percentageEarnedString)%")
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                        }//: HSTACK
                        .frame(width: (totalProgress * geo.size.width))
                    }//: IF
                }//: ZSTACK
                .frame(height: 25)
            }//: GEO READER
        }//: VSTACK
        .accessibilityElement()
        .accessibilityLabel(Text("Total CE \(getCEMeasurement) earned for the \(renewal.renewalPeriodName)"))
        .accessibilityHint(
            Text("So far in the \(renewal.renewalPeriodName), you've completed \(percentageEarnedString)% of the total CEs required. Keep up the good work!")
        )
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    TotalRenewalProgressBar(renewal: .example)
        .environmentObject(DataController(inMemory: true))
}

//
//  RenewalPeriodSheetTitleView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/16/25.
//

import SwiftUI

struct RenewalPeriodSheetTitleView: View {
    // MARK: - PROPERTIES
    let renewalPeriod: RenewalPeriod?
    
    // MARK: - BODY
    var body: some View {
        Spacer()
        VStack {
            if let existingRenewal = renewalPeriod {
                if existingRenewal.renewalPeriodName != "" {
                    Text(existingRenewal.renewalPeriodName)
                        .font(.largeTitle)
                }
            } else {
                Text("Add New Renewal Period")
                    .font(.title)
                    .padding()
            }
        }//: VSTACK
        .padding(.bottom, 20)
    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    RenewalPeriodSheetTitleView(renewalPeriod: .example)
}

//
//  IssuerRowView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/10/25.
//

import SwiftUI

struct IssuerRowView: View {
    // MARK: - PROPERTIES
    @ObservedObject var issuer: Issuer
    
    // Property for determining if the row was selected
    var isSelected: Bool = false
    
    // MARK: - BODY
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                // Issuer name
                Text(issuer.issuerIssuerName)
                    .font(.title2)
                    .bold()
                // Issuer country: USA if United States,
                // full name if other country
                if let issueCountry = issuer.country {
                    if issueCountry.countryAlpha3 == "USA" {
                        let stateName = issuer.state?.USStateName ?? "Select State"
                        let alpha3Text = issueCountry.countryAlpha3
                        HStack {
                            Text(alpha3Text)
                            Text(" | ")
                            Text(stateName)
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        let countryName = issueCountry.countryName
                        Text(countryName)
                    }
                }
            }//: VSTACK
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 10)
            }//: IF isSelected
            
        }//: HSTACK
        
    }//: BODY
    
}//: ---------------- STRUCT ---------------------

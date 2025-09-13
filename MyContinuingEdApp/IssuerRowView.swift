//
//  IssuerRowView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/10/25.
//

import SwiftUI

struct IssuerRowView: View {
    // MARK: - PROPERTIES
    let issuer: Issuer
    let selectedIssuer: Issuer?
    
    // MARK: - BODY
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                // Issuer name
                Text(issuer.name)
                    .font(.title)
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
            if issuer == selectedIssuer {
                Image(systemName: "checkmark.circle.fill")
            }
        }//: HSTACK
        
    }//: BODY
    
}

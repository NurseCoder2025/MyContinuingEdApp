//
//  CountryRowView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/10/25.
//

import SwiftUI

// This view is called by the CountryListSheet struct and displays each individual
// Country object currently stored in persistent storage.

struct CountryRowView: View {
    // MARK: - PROPERTIES
    let country: Country
    let selectedCountry: Country?
    
    // MARK: - BODY
    var body: some View {
        VStack {
            HStack {
                Text(country.countryAbbrev)
                    .font(.title)
                Text(country.countryName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }//: HSTACK
            
            if country == selectedCountry {
                Image(systemName: "checkmark.circle.fill")
            }
        }//: VSTACK
    }
}

// MARK: - PREVIEW
#Preview {
    CountryRowView(country: .example, selectedCountry: .example)
}

//
//  StatePickerRowView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/12/25.
//

import SwiftUI

// Showing each row for a U.S. state picker in IssuerSheet view

struct StatePickerRowView: View {
    // MARK: - PROPERTIES
    let state: USState
    
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text("\(state.USStateAbbreviation)")
                .bold()
            Text("|")
            Text(state.USStateName)
                .foregroundStyle(.secondary)
        }//: HSTACK
    }
}



//
//  HelpSheetRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/26/26.
//

import SwiftUI

struct HelpSheetRowView: View {
    // MARK: - PROPERTIES
    let rowIcon: String
    let rowTitle: String
    let rowText: String
    // MARK: - BODY
    var body: some View {
        HStack {
            Image(systemName: rowIcon)
                .imageScale(.large)
                .font(.largeTitle)
            
            VStack(spacing: 5) {
                Text(rowTitle)
                    .font(.headline)
                Text(rowText)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }//: VSTACK
            
        }//: HSTACK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEw
#Preview {
    HelpSheetRowView(
        rowIcon: "questionmark.circle.fill",
        rowTitle: "Help About",
        rowText: "Here's how you do this..."
    )
}

//
//  SettingsHeaderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/15/25.
//

import SwiftUI

struct SettingsHeaderView: View {
    // MARK: - PROPERTIES
    let headerText: String
    let headerImage: String
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text(headerText)
                .font(.title3)
            Spacer()
            Image(systemName: headerImage)
                .font(.title3)
            
        }//: HSTACK
        .accessibilityLabel(Text(headerText))
    }//: BODY
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    SettingsHeaderView(headerText: "Sample Text", headerImage: "info.circle.fill")
}

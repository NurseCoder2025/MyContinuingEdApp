//
//  NoCertificateView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/18/25.
//

import SwiftUI

struct NoItemView: View {
    // MARK: - PROPERTIES
    let noItemTitleText: String
    let noItemMessage: String
    var noItemImage: String = "doc.circle"
    
    // MARK: - BODY
    var body: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label(noItemTitleText, systemImage: noItemImage)
            } description: {
                Text(noItemMessage)
            }
        } else {
            VStack {
                Text(noItemTitleText)
                    .font(.title3)
                Image(systemName: noItemImage)
                    .font(.largeTitle)
                Text(noItemMessage)
                    .foregroundStyle(.secondary)
            } //: VSTACK
            
        } //: IF AVAILABLE
    }
}

// MARK: - PREVIEW


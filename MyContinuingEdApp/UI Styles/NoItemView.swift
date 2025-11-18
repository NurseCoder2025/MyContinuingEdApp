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
                Image(systemName: noItemImage)
                    .font(.largeTitle)
                    .padding(.bottom, 5)
                Text(noItemTitleText)
                    .font(.title2)
                    .padding(.bottom, 2)
                Text(noItemMessage)
                    .foregroundStyle(.secondary)
            } //: VSTACK
            
        } //: IF AVAILABLE
    }
}

// MARK: - PREVIEW


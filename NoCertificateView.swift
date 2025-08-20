//
//  NoCertificateView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/18/25.
//

import SwiftUI

struct NoCertificateView: View {
    // MARK: - PROPERTIES
    
    // MARK: - BODY
    var body: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label("No certificate", systemImage: "doc.circle")
            } description: {
                Text("You haven't added a CE certificate for this activity yet.")
            }
        } else {
            VStack {
                Text("No Certificate")
                    .font(.title3)
                Image(systemName: "doc.badge.plus")
                    .font(.largeTitle)
                Text("You haven't added a CE certificate for this activity yet.")
                    .foregroundStyle(.secondary)
            } //: VSTACK
            
        } //: IF AVAILABLE
    }
}

// MARK: - PREVIEW


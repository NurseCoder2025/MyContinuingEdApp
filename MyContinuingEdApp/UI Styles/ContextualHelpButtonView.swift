//
//  ContextualHelpButtonView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/26/26.
//

import SwiftUI

struct ContextualHelpButtonView: View {
    // MARK: - CLOSURES
    var toggleHelpSheet: () -> Void = { }
    // MARK: - BODY
    var body: some View {
        Button {
            toggleHelpSheet()
        } label: {
            Label("Help", systemImage: "questionmark.circle.fill")
                .foregroundColor(.white)
        }//: BUTTON
        .buttonStyle(.borderedProminent)
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ContextualHelpButtonView()
}

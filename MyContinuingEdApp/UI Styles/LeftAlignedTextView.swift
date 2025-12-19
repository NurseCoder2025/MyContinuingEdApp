//
//  LeftAlignedTextView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/19/25.
//

import SwiftUI

struct LeftAlignedTextView: View {
    // MARK: - PROPERTIES
    let text: String
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text(text)
                .multilineTextAlignment(.leading)
            Spacer()
        }//: HSTACK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    LeftAlignedTextView(text: "Hello, world!")
}

//
//  GroupBoxLabelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/30/25.
//

import SwiftUI

struct GroupBoxLabelView: View {
    // MARK: - PROPERTIES
    let labelText: String
    let labelImage: String
    // MARK: - BODY
    var body: some View {
        VStack {
            HStack {
                Text(labelText)
                Spacer()
                Image(systemName: labelImage)
                    .imageScale(.large)
            }//: HSTACK
            .padding(.bottom, 5)
            .padding([.leading, .trailing], 10)
            
            Divider()
        }//: VSTACK
        .accessibilityLabel(Text(labelText))
        .padding(.bottom, 5)
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    GroupBoxLabelView(labelText: "More Info", labelImage: "info.circle.fill")
}

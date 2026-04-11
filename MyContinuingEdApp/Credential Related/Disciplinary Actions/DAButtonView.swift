//
//  DAButtonView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/17/25.
//

import SwiftUI

/// A reuseable button style intended for formatting the various disciplinary actions in the
/// DisciplinaryActionItem sheet.  Takes a closure to pass up behavior to the parent view.
struct DAButtonView: View {
    // MARK: - PROPE
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.translucentGreyGradient) // TODO: Update background color based on selection
                .frame(width: 150, height: 44)
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.caption)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .padding(.trailing, 10)
                    }
                }//: HSTACK
            }//: BUTTON
            .foregroundStyle(.primary)
            .padding(.leading, 10)
        }//: ZSTACK
    }
}


// MARK: - PREVIEW
#Preview {
    DAButtonView(title: "", isSelected: false, action: {})
}

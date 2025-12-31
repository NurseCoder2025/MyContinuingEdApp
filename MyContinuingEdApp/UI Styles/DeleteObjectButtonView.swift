//
//  DeleteObjectButtonView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/29/25.
//

import SwiftUI

struct DeleteObjectButtonView: View {
    // MARK: - PROPERTIES
    let buttonText: String
    var onDelete: () -> Void
    // MARK: - BODY
    var body: some View {
        HStack {
            Spacer()
            Button {
                onDelete()
            } label: {
                HStack {
                    Text(buttonText)
                        .bold()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.large)
                }//: HSTACK
                .padding([.horizontal, .vertical], 10)
                .foregroundStyle(Color.white)
                .background(alignment: .leading) {
                    Capsule().fill(Color.red)
                    
                }
                .frame(maxWidth: .infinity)
            }//: BUTTON
            Spacer()
        }//: HSTACK
    }//: BODY
    // MARK: - INIT
    init(buttonText: String, onDelete: @escaping () -> Void) {
        self.buttonText = buttonText
        self.onDelete = onDelete
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    DeleteObjectButtonView(buttonText: "Delete Credential", onDelete: {})
}

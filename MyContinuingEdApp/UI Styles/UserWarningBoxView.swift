//
//  UserWarningBoxView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 5/4/26.
//

import SwiftUI

struct UserWarningBoxView: View {
    // MARK: - PROPERTIES
    let warningTitle: String
    let warningText: String
    var warningAccentColor: Color = .red
    
    var showActionButton: Bool = false
    var buttonLabelText: String = ""
    // MARK: - CLOSURES
    var onTap: () -> Void = { }
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text(warningTitle)
                .font(.title3)
                .foregroundStyle(warningAccentColor)
            
            Divider()
            
            Text(warningText)
                .font(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
            
            if showActionButton {
                HStack {
                    Spacer()
                    Button(action: onTap) {
                        Text(buttonLabelText)
                            .foregroundStyle(.white)
                    }//: BUTTON
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing, 10)
                }//: HSTACK
            }//: IF (showActionButton)
        }//: VSTACK
        .background {
            RoundedRectangle(cornerRadius: 10)
                .border(warningAccentColor.opacity(0.3), width: 3.5)
                .shadow(radius: 3.0)
        }//: BACKGROUND
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    UserWarningBoxView(warningTitle: "Notice", warningText: "This is a sample warning box to alert the user about a condition that needs to be corrected.")
}

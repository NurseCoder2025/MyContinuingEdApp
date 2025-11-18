//
//  RenewalStatBoxView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/18/25.
//

import SwiftUI

struct RenewalStatBoxView: View {
    // MARK: - PROPERTIES
    let width: CGFloat
    let height: CGFloat
    let titleText: String
    let statValue: String
    let subscriptText: String
    let boxColor: Color?
    let textColor: Color?
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: width, height: height)
                .foregroundColor(boxColor ?? .secondary)
                .shadow(radius: 2)
            
            VStack {
                Text(titleText)
                    .padding(.bottom, 2)
                Text("\(statValue)")
                    .font(.title3)
                    .bold()
                    .padding(.bottom, 2)
                Text(subscriptText)
                    .font(.caption)
            }//: VSTACK
            .foregroundStyle(textColor ?? .primary)
        }//: ZSTACK
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel(titleText)
        .accessibilityHint(Text("\(statValue) \(subscriptText)"))
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RenewalStatBoxView(
        width: 150,
        height: 100,
        titleText: "Hello there",
        statValue: "150 days",
        subscriptText: "To renew",
        boxColor: Color.yellow,
        textColor: nil
    )
}

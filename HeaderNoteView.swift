//
//  HeaderNoteView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/15/25.
//

import SwiftUI

// Purpose: To create a consistent rectangle with grey background and whatever instructional text needs to be
// shown to the user on a given sheet or screen.



struct HeaderNoteView: View {
    // MARK: - PROPERTIES
    let titleText: String
    let messageText: String
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.translucentGreyGradient)
                .frame(width: 350, height: 180)
            
            VStack {
                Text(titleText)
                    .font(.title)
                
                ScrollView {
                    Text(messageText)
                        .font(.caption)
                }//: SCROLL
                .frame(width: 300)
                .frame(maxHeight: 100)
              
            }//: VSTACK
            .padding(.top, 35)
            
            
        }//: ZSTACK
    }
}

// MARK: - PREVIEW
#Preview {
    HeaderNoteView(titleText: "Hello there", messageText: "An important message for you!")
}

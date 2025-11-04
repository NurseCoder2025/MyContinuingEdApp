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
    
    var dismissAction: () -> Void
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.translucentGreyGradient)
                .frame(width: 350, height: 200)
            
            VStack {
                HStack {
                    Text(titleText)
                        .font(.title2)
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    // Button for passing a closure
                    Button {
                        dismissAction()
                    }label: {
                        Text("x")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 10)
                }//: HSTACK
                .frame(width: 330)
                
                ScrollView {
                    Text(messageText)
                        .font(.caption)
                }//: SCROLL
                .frame(width: 300)
                .frame(maxHeight: 180)
              
            }//: VSTACK
            .padding(.top, 35)
            
            
        }//: ZSTACK
    }
}

// MARK: - PREVIEW
#Preview {
    HeaderNoteView(titleText: "Hello there", messageText: "An important message for you!", dismissAction: {})
}

//
//  CredentialCatBoxView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/6/25.
//

// Purpose: To display a card shape that has an icon, text, and badge icon
// for each type of credential object.  A grid of these objects will be displayed
// in the CredentialManagementSheet so the user can see how many credentials are in
// each category, as applicable

import SwiftUI

struct CredentialCatBoxView: View {
    //: MARK: - PROPERTIES
    @State var icon: String
    @State private var iconColor: Color = .blue
    @State var text: String
    
    var badgeCount: Int = 0
    
    let sfWithExtraSpacing = [
        "folder.fill",
        "person.text.rectangle.fill",
        "questionmark.circle.fill"
    ]
    //: MARK: - BODY
    var body: some View {
            ZStack {
                // Background Rounded Rectangle w/ overlay
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
                    .overlay(
                        Group {
                            if badgeCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 25, height: 25)
                                    Text("\(badgeCount)")
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                        .bold()
                                }
                                .padding([.top, .trailing], 8)
                            }
                        }//: GROUP
                        , alignment: .topTrailing
                    )//: OVERLAY
                
                VStack(alignment: .leading) {
                    Spacer()
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .background(Color.clear)
                            .foregroundStyle(iconColor)
                            .padding(.leading, 10)
                    LeftAlignedTextView(text: text)
                        .font(.title3)
                        .bold()
                        .padding(.leading, 10)
                    Spacer()
                    
                }//: VSTACK
            }//: ZSTACK
            
    }//: BODY
}//: STRUCT

//: MARK: - PREVIEW
struct CredentialCatBoxView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialCatBoxView(
            icon: "person.text.rectangle.fill",
            text: "License" ,
            badgeCount: 3
        )
            .previewLayout(.sizeThatFits)
    }
}

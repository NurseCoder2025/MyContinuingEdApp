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
    
    
    //: MARK: - BODY
    var body: some View {
            ZStack {
                // Background Rounded Rectangle w/ overlay
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 150, height: 75)
                    .overlay(
                        Group {
                            if badgeCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 24, height: 24)
                                    Text("\(badgeCount)")
                                        .foregroundColor(.white)
                                        .font(.caption)
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
                        .foregroundStyle(iconColor)
                        .font(.title)
                    Text(text)
                        .padding(.top, 5)
                    Spacer()
                    
                }//: VSTACK
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 16)
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

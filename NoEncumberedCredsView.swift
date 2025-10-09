//
//  NoEncumberedCredsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/7/25.
//

// Purpose: To inform the  user that no credentials are currently encumbered
// when the EncumberedCredentialListSheet is opened and there are none to show

import SwiftUI

struct NoEncumberedCredsView: View {
    //: MARK: - PROPERTIES
    
    //: MARK: - BODY
    var body: some View {
        VStack {
            Image(systemName: "slash.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                
            Text("No Encumbered Credentials")
                .font(.title2)
                .padding(.top, 5)
            
            Text("Rejoice!")
                .font(.title3)
                .padding([.top, .bottom], 5)
            
            Text("Currently all of your credentials are unencumbered. If that has changed, then navigate to the applicable credential and add a disciplinary action or restriction to it.")
                .multilineTextAlignment(.leading)
                .padding([.leading, .trailing], 45)
            
        }//: VSTACK
        .frame(maxHeight: .infinity)
        .alignmentGuide(.top) { d in d[VerticalAlignment.center] }
        
    }//: BODY
}//: STRUCT

//: MARK: - PREVIEW
#Preview {
    NoEncumberedCredsView()
}

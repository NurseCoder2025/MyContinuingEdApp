//
//  HelpInfoSheetView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/6/26.
//

import SwiftUI

struct HelpInfoSheetView: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    let headerText: String
    let bodyText: String
    
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 10) {
            Text(headerText)
                .font(.title3)
                .padding(.horizontal, 10)
            
            Divider()
            ScrollView(.vertical) {
                Text(bodyText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
                
                // MARK: OK Button
                Button {
                    dismiss()
                } label: {
                    Text("OK")
                }//: BUTTON
                .buttonStyle(.borderedProminent)
            }//: SCROLL
            
        }//: VSTACK
         // MARK: - TOOLBAR
         .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         dismiss()
                     }, label: {
                         Text("Close")
                     })
                 }//: TOOLBAR ITEM
             }//: TOOLBAR
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    HelpInfoSheetView(
        headerText: "Explaination",
        bodyText: "Do or do not. There is no try."
    )
}

//
//  NoIssuersView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/12/25.
//

import SwiftUI

// To be shown only when the user hasn't entered in any credential issuers
// like licensing boards or the like

struct NoIssuersView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    let titleText: String = "Add Credential Issuer"
    let message: String = """
    You haven't added a credential issuer yet.
    
    This is a governing body like a licensing board or similar entity 
    that has the authority to issue a credential. 
    
    Add one by tapping on the button below.
    """
    let image: String = "questionmark.app.fill"
  
    
    var addNewIssuer: () -> Void
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 10) {
            Group {
                Image(systemName: image)
                    .imageScale(.large)
                    .font(.largeTitle)
                Text(titleText)
                    .font(.title3)
                Text(message)
                    .foregroundStyle(Color.gray.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .padding()
            }//: GROUP
                
                
                // Add issuer button
                Button {
                    addNewIssuer()
                } label: {
                    Label("Add Credential Issuer", systemImage: "person.text.rectangle.fill")
                }
                .buttonStyle(.borderedProminent)
            } //: VSTACK
            // MARK: - TOOLBAR
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
            }//: TOOLBAR
           
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    NoIssuersView(addNewIssuer: {})
}

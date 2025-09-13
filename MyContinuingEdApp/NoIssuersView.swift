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
    @Environment(\.dismiss) var dismiss
    
    let titleText: String = "Add Credential Issuer"
    let message: String = "You haven't added a credential issuer yet. This is a governing body like a licensing board or similar entity that has the authority to issue a credential. Add one by tapping on the button below."
    let image: String = "questionmark.app.fill"
    
    // Property to bring up the IssuerSheet
    @State private var showIssuerSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label(titleText, systemImage: image)
            } description: {
                Text(message)
            }
        } else {
            VStack {
                Text(titleText)
                    .font(.title3)
                Image(systemName: image)
                    .font(.largeTitle)
                Text(message)
                    .foregroundStyle(.secondary)
                    .padding()
                
                
                // Add issuer button
                Button {
                    showIssuerSheet = true
                } label: {
                    Label("Add Credential Issuer", systemImage: "person.text.rectangle.fill")
                }
                .buttonStyle(.borderedProminent)
            } //: VSTACK
            // MARK: - TOOLBAR
            .toolbar {
                Button(action: {dismiss()}){
                    DismissButtonLabel()
                }.applyDismissStyle()
            }
            // MARK: - SHEETS
            .sheet(isPresented: $showIssuerSheet) {
                IssuerSheet(issuer: nil)
            }
        } //: IF AVAILABLE
    }
}

// MARK: - PREVIEw
#Preview {
    NoIssuersView()
}

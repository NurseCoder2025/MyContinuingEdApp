//
//  NoSpecialCatsView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/17/25.
//

// Purpose: To display text and a button whenever no special category objects exist in persistent
// storage, such as the first run of the app or user deletion of all objects.

import SwiftUI

struct NoSpecialCatsView: View {
    // MARK: - PROPERTIES
    @State private var showSpecialCatsSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text("No Special CE Categories, yet...")
                .font(.largeTitle)
            
            Image(systemName: "slash.circle")
                .font(.largeTitle)
            
            Text("A special CE category is a subject like law or ethics that a credential issuer requires as part of regular continuing education requirements.  Usually, a portion of the total CE hour or units required must include so many in whatever special categories the governing body mandates. Depending on what type of credential you have and your governing body's requirements are, this may or may not apply to you.")
                .multilineTextAlignment(.leading)
            
            Text("Example: /n- 40 CE hours required total for renewal/n- 5 hours of ethics required/n- Total: 35 non-specified hours and 5 hours on ethics = 40 CE hours")
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text("If in doubt about whether you need to add a special CE category or not, please double-check with your licensing or credentialing body.")
                .multilineTextAlignment(.leading)
                .font(.callout)
                .padding(.bottom, 20)
            
            Button {
                showSpecialCatsSheet = true
            } label: {
                Label("Add Special Category", systemImage: "plus")
                    .font(.title)
            }
            .buttonStyle(.borderedProminent)
            
        }//: VSTACK
        // MARK: - SHEETS
        .sheet(isPresented: $showSpecialCatsSheet) {
            SpecialCategorySheet(existingCat: nil)
        }
    }
}

// MARK: - PREVIEW
#Preview {
    NoSpecialCatsView()
}

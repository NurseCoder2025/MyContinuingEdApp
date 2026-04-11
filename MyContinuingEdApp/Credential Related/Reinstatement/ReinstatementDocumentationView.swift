//
//  ReinstatementDocumentationView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/8/26.
//

import SwiftUI

struct ReinstatementDocumentationView: View {
    // MARK: - PROPERTIES
    @ObservedObject var reinstatement: ReinstatementInfo
    
    // MARK: - BODY
    var body: some View {
        Section {
            TextField(
                "Documents Needed",
                text: $reinstatement.riDocumentationNeeded,
                axis: .vertical
            )
        } header: {
            Text("Documentation Needed")
        } footer: {
            Text("Use this section for listing all documents needed to reinstate your credential, including CE certificates, photo ID, etc.")
        }//: SECTION
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ReinstatementDocumentationView(reinstatement: .example)
}

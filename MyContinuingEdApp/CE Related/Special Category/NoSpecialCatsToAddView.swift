//
//  NoSpecialCatsToAddView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/8/26.
//

// This view is intended to be used in the ReinstatementInfoSheet or RSCRowView

import SwiftUI

struct NoSpecialCatsToAddView: View {
    // MARK: - PROPERTIES
    
    // MARK: - CLOSURES
    var createSpecialCategory: () -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Text("No Credential-Specific CE Requirements")
                .bold()
                .padding(.vertical, 10)
            
                Text("""
                    Either you haven't added any required CE categories for this credential yet or none exist for your credential. 
                    
                    If your licensing board requires specific CE requirements for renewal and reinstatement, please click on the button below to add them now. Otherwise, skip over this section.
                    """)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
            
            Button {
                createSpecialCategory()
            } label: {
                Text("Add Credential-Specific Category")
            }//: BUTTON
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 10)
            
        }//: VSTACK
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.3))
        )//: BACKGROUND
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    NoSpecialCatsToAddView(createSpecialCategory: {})
}

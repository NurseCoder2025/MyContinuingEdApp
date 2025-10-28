//
//  NoDAIsView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/16/25.
//

// Purpose: to let the user know that no Disciplinary Action Items (DAIs) have been
// entered in the app yet and to provide them with a convenient button to do so.

import SwiftUI

struct NoDAIsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var credential: Credential
    
    // Closure to handle adding a new DAI and presenting the sheet in parent
    var onAddDAI: () -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Group {
                Image(systemName: "circle.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                
                Text("No Disciplinary Actions Saved")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
            }//: GROUP
            .padding(.bottom, 20)
            
            Button {
                onAddDAI()
            } label: {
                Label("Add Disciplinary Action", systemImage: "plus")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
        
            
        }//: VSTACK
    }//: BODY
}

// MARK: - PREVIEW
#Preview {
    NoDAIsView(credential: .example, onAddDAI: {})
}

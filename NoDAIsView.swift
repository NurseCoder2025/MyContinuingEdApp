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
    @State private var showDAISheet: Bool = false
    
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
                showDAISheet = true
            } label: {
                Label("Add Disciplinary Action", systemImage: "plus")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
        
            
        }//: VSTACK
        // MARK: - SHEETS
        .sheet(isPresented: $showDAISheet) {
            DisciplinaryActionItemSheet(disciplinaryAction: nil)
        }
    }
}

// MARK: - PREVIEW
#Preview {
    NoDAIsView()
}

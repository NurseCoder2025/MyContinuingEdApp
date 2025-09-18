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
            Text("No Disciplinary Actions Saved")
                .font(.largeTitle)
            
            Image(systemName: "circle.slash")
                .font(.largeTitle)
                .foregroundStyle(.red)
            
            Spacer()
            
            Button {
                showDAISheet = true
            } label: {
                Label("Add Disciplinary Action", systemImage: "plus")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
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

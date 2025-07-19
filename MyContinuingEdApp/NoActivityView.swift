//
//  NoActivityView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/18/25.
//

import SwiftUI

struct NoActivityView: View {
    var body: some View {
        Text("No Activity Selected")
        
        Button("New CE Activity") {
            // TODO: button functionality
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - Preview
struct NoActivityView_Previews: PreviewProvider {
    static var previews: some View {
        NoActivityView()
    }
}

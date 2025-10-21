//
//  DismissButtonCustomizations.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/12/25.
//

import SwiftUI

// MARK: - CUSTOM BUTTON STYLE
// Creating a style for all dismiss buttons in the app
struct DismissButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 35, height: 35)
            .background(
                configuration.isPressed ? Color.red.opacity(0.7) : Color.red
            )
            .foregroundStyle(.white)
            .clipShape(.circle)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
           
    }

    
    
}

// MARK: - Button Extension
extension Button {
    func applyDismissStyle() -> some View {
        self.buttonStyle(DismissButtonStyle())
    }
}



// MARK: - Custom LABEL
// Creating a struct that holds a standard label for each dimiss button
struct DismissButtonLabel: View {
    // MARK: - PROPERTIES
    let text: String = "Dismiss"
    let systemImage: String = "x.circle"
    
    // MARK: - BODY
    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.title)
            .bold()
    }
}



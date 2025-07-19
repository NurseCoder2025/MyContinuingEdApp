//
//  ActivityView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/18/25.
//

import SwiftUI

struct ActivityView: View {
    // MARK: - Properties
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Text("Activity View")
    }
}

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(activity: .example)
    }
}

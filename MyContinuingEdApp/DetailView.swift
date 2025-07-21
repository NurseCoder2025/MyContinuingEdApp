//
//  DetailView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI

struct DetailView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - BODY
    var body: some View {
        if let activity = dataController.selectedActivity {
            ActivityView(activity: activity)
        } else {
            NoActivityView()
        }
    }
}


// MARK: - PREVIEW
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
    }
}

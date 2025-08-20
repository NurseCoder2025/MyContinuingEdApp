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
    
    // For customizing the navigation path since there are more than
    // three views in this trisplit navigation app
    @State private var navigationPath: NavigationPath = NavigationPath()
    
    // MARK: - BODY
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if let activity = dataController.selectedActivity {
                ActivityView(activity: activity)
                    .navigationDestination(for: ActivityReflection.self) { reflection in
                        ActivityReflectionView(activity: activity, reflection: reflection)
                    }
            } else {
                NoActivityView()
            }
        } //: NAV STACK
    } //: BODY
}


// MARK: - PREVIEW
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
    }
}

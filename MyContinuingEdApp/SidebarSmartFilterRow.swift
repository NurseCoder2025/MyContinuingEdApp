//
//  SidebarSmartFilterRow.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/16/25.
//

import SwiftUI

struct SidebarSmartFilterRow: View {
    // MARK: - PROPERTIES
    var filter: Filter = .allActivities
    
    // MARK: - BODY
    var body: some View {
        NavigationLink(value: filter) {
            Label(filter.name, systemImage: filter.icon)
        } //: NAV LINK
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    SidebarSmartFilterRow()
}

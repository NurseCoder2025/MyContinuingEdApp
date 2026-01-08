//
//  ReinstatementInfoView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct ReinstatementInfoSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var reinstatement: ReinstatementInfo
    
    // MARK: - BODY
    var body: some View {
        Form {
            // Fees & Deadline Info
            FeeAndDeadlineView(reinstatement: reinstatement)
            
            // CE Requirements
            
            // Documentation needed
            
            // Additional items (background check, interview, test)
            
        }//: FORM
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ReinstatementInfoSheet(reinstatement: .example)
}

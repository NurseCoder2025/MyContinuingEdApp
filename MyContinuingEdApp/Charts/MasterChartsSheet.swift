//
//  MasterChartsSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import SwiftUI

struct MasterChartsSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            Text("Charts & Stats")
                .font(.title)
                .bold()
            
            Divider()
            
            ScrollView {
                LazyVStack {
                    
                    CeEarnedByMonthChartView()
                    
                    MoneySpentByMonthView()
                    
                }//: LAZY V STACK
            }//: SCROLLVIEW
        }//: NAV STACK
        // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                }
            }//: TOOLBAR
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    MasterChartsSheet()
        .environmentObject(DataController(inMemory: true))
}

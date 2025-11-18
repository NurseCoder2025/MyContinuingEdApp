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
        NavigationView {
            VStack {
                Text("Charts & Stats")
                    .font(.title)
                    .bold()
                
                Divider()
                
                ScrollView {
                    LazyVStack {
                        
                        CeEarnedByMonthChartView()
                            .padding([.leading, .trailing], 20)
                            .padding([.top,.bottom], 20)
                        
                        MoneySpentByMonthView()
                            .padding([.leading, .trailing], 20)
                        
                    }//: LAZY V STACK
                }//: SCROLLVIEW
            }//: VSTACK
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
        }//: NAV VIEW
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    MasterChartsSheet()
        .environmentObject(DataController(inMemory: true))
}

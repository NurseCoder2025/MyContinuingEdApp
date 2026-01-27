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
                    LazyVStack(spacing: 20) {
                        
                        CeEarnedByMonthChartView()
                            .padding(.horizontal, 10)
                        
                        MoneySpentByMonthView()
                            .padding(.horizontal, 10)
                           
                        Text("More enhancements and charts to come... 😀")
                            .font(.title3)
                            .padding(.horizontal, 20)
                        
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

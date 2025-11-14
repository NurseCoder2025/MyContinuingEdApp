//
//  CeEarnedChartView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import Charts
import SwiftUI

struct CeEarnedByMonthChartView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - COMPUTED PROPERTIES
    var ceData: [CeEarned] {
        var ceEarnedData: [CeEarned] = []
        let cesEarned = dataController.calculateCEsEarnedByMonth()
        
        for key in cesEarned.keys {
            let ceEarned = CeEarned(amount: cesEarned[key] ?? 0, earnedDate: key)
            ceEarnedData.append(ceEarned)
        }//: LOOP
        
        return ceEarnedData
    }
    
    // MARK: - BODY
    var body: some View {
        if ceData.isEmpty {
            NoItemView(
                noItemTitleText: "No CEs Completed Yet!",
                noItemMessage: "There is no chart to show you because you haven't completed any CE activities yet.  What are you waiting for?  Get out there and complete some so we can show you this nice chart of how many you're earning each month.",
                noItemImage: "chart.bar.xaxis"
            )
        } else {
            VStack {
                Text("CEs Earned by Month")
                Chart {
                    ForEach(ceData) { ce in
                        BarMark(
                            x: .value(ce.dateLabel, ce.earnedDate),
                            y: .value("Cost", ce.amount)
                        )
                    }//: LOOP
                    
                }//: CHART
                
            }//: VSTACK
        }//: IF ELSE
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    CeEarnedByMonthChartView()
}

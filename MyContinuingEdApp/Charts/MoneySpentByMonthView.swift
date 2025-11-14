//
//  MoneSpentByMonthView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import Charts
import SwiftUI

struct MoneySpentByMonthView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - COMPUTED PROPERTIES
    var moneyData: [CeCost] {
        var ceCosts = [CeCost]()
        let allMoneySpent = dataController.calculateMoneySpentByMonth()
        
        for key in allMoneySpent.keys {
            let cost = CeCost(spentDate: key, cost: allMoneySpent[key] ?? 0)
            ceCosts.append(cost)
        }
        return ceCosts
    }//: moneyData
    
    // MARK: - BODY
    var body: some View {
        if moneyData.isEmpty {
            NoItemView(
                noItemTitleText: "Nothing Spent Yet!",
                noItemMessage: "There is no chart to show you because you haven't had to pay for any CEs yet.  Of course, if you're clever and can complete all of your CEs for free then you don't need this graph 😉.  Once you do pay for some, though, we will show you a nice line chart that will show your CE spending over time.",
                noItemImage: "chart.xyaxis.line"
            )
        } else {
            VStack {
                Text("Money Spent on CEs by Month")
                Chart {
                    ForEach(moneyData) { cost in
                        LineMark(
                            x: .value(cost.dateLabel, cost.spentDate),
                            y: .value("Cost", cost.cost)
                        )
                        
                    }//: LOOP
                }//: Chart
                
            }//: VSTACK
        }//: IF ELSE
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    MoneySpentByMonthView()
}

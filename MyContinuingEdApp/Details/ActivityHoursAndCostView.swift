//
//  ActivityHoursAndCostView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/26/25.
//

// Purpose: To draw the UI controls for the Hours & Cost section in the parent
// view (ActivityView) in order to keep the code for that view broken into
// manageable parts for easier maintenance and reuse.

import SwiftUI

struct ActivityHoursAndCostView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section("CE Awarded & Cost") {
                    HStack {
                        Text("CE Earned:")
                            .bold()
                            .padding(.trailing, 5)
                        TextField("Earned CE:", value: $activity.ceAwarded, formatter: hoursFormatter , prompt: Text("amount of CE awarded"))
                            .keyboardType(.decimalPad)
                        
                        Picker("", selection: $activity.hoursOrUnits){
                            Text("hours").tag(Int16(1))
                            Text("units").tag(Int16(2))
                        }//: PICKER
                        .labelsHidden()
                
                    } //: HSTACK
            
                    
                    
                    HStack {
                        Text("Cost:")
                            .bold()
                            .padding(.trailing, 5)
                        TextField("Activity Cost:", value: $activity.cost, formatter: currencyFormatter, prompt: Text("Cost/Fees"))
                            .keyboardType(.decimalPad)
                            
                    } //: HSTACK
                
            } //: Contact Hours & Cost subsection
        }//: GROUP
    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    ActivityHoursAndCostView(activity: .example)
}

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
                            .onSubmit { dismissKeyboard() }//: ON SUBMIT
                        
                        Picker("", selection: $activity.hoursOrUnits){
                            Text("hours").tag(Int16(1))
                            Text("units").tag(Int16(2))
                        }//: PICKER
                        .labelsHidden()
                    } //: HSTACK
            
                // The reason for including this section is to ensure that
                // any units awarded for an activity can be converted over
                // to clock hours if the activity will be applied to multiple
                // credentials where at least one only measures CEs in hours.
                // This will enable the relevant DataController functions to
                // calculate the amount of CE earned correctly in such cases.
                if activity.hoursOrUnits == 2 {
                    VStack {
                        Text("Please enter the number of clock hours awarded as listed on the certificate. If the certificate does not specify, leave the field blank.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text("Clock Hours Awarded:")
                                .bold()
                            TextField("Clock Hours Awarded:", value: $activity.clockHoursAwarded, formatter: ceHourFormatter)
                                .frame(maxWidth: 50)
                                .keyboardType(.decimalPad)
                                .onSubmit {
                                    dismissKeyboard()
                                }//: ON SUBMIT
                        }//: HSTACK
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }//: VSTACK
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.3))
                    )//: Background
                }//: IF
                    
                    HStack {
                        Text("Cost:")
                            .bold()
                            .padding(.trailing, 5)
                        TextField("Activity Cost:", value: $activity.cost, formatter: currencyFormatter, prompt: Text("Cost/Fees"))
                            .keyboardType(.decimalPad)
                            
                    } //: HSTACK
                
            } //: Contact Hours & Cost subsection
            // MARK: - ON CHANGE
            .onChange(of: activity.hoursOrUnits) { newValue in
                if newValue == 1 {
                    activity.clockHoursAwarded = 0
                }
            }//: ON CHANGE
            
        }//: GROUP
    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    ActivityHoursAndCostView(activity: .example)
}

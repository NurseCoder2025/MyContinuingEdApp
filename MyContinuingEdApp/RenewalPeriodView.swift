//
//  RenewalPeriodView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import SwiftUI

struct RenewalPeriodView: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    // This is passed in via the view's initializer instead of the environment
    let dataController: DataController
    
    @ObservedObject var renewalPeriod: RenewalPeriod
    
    // Renewal period properties
    @State private var periodStart: Date = Date.renewalStartDate
    @State private var periodEnd: Date = Date.renewalEndDate
    
    // MARK: - BODY
    var body: some View {
            VStack {
                if renewalPeriod.renewalPeriodName != "" {
                    Text(renewalPeriod.renewalPeriodName)
                        .font(.largeTitle)
                } else {
                    Text("Add New Renewal Period")
                        .font(.largeTitle)
                }
            }//: VSTACK
            .padding(.bottom, 20)
        
            VStack {
                Group {
                    Text("Enter the date the renewal period begins:")
                        .font(.headline)
                    Text("If you don't know the exact date, enter January 1st of the starting year")
                        .font(.caption)
                    Divider()
                    DatePicker(
                        "Starting Date",
                        selection: $periodStart,
                        displayedComponents: .date
                    )
                    .padding([.leading, .trailing], 35)
                }//: GROUP
                
                Divider()
                Group {
                    Text("Enter the date your renewal period ends:")
                        .font(.headline)
                    Text("If you don't know the exact date, enter the last day of the month in which the renewal ends of the respective year.")
                        .font(.caption)
                        .padding([.leading, .trailing], 30)
                    Divider()
                    DatePicker(
                        "Ending Date",
                        selection: $periodEnd,
                        displayedComponents: .date
                    )
                    .padding([.leading, .trailing], 35)
                    .padding(.bottom, 20)
                } //: GROUP
                
                
                Button {
                    renewalPeriod.periodStart = periodStart
                    renewalPeriod.periodEnd = periodEnd
                    dataController.save()
                    dismiss()
                } label: {
                    Text("Save & Dismiss")
                }
                .buttonStyle(.borderedProminent)
                
                
            }//: VSTACK
            .onAppear {
                periodStart = renewalPeriod.periodStart ?? Date.renewalStartDate
                periodEnd = renewalPeriod.periodEnd ?? Date.renewalEndDate
            }
            
            .onReceive(renewalPeriod.objectWillChange) { _ in
                dataController.queueSave()
            }
            .onChange(of: renewalPeriod.periodStart) { _ in
                dataController.assignActivitiesToRenewalPeriod()
            }
            .onChange(of: renewalPeriod.periodEnd) { _ in
                dataController.assignActivitiesToRenewalPeriod()
            }
            
    } //: BODY
    
    // MARK: - Custom INIT
    
    init(renewalPeriod: RenewalPeriod? = nil, dataController: DataController) {
        if let existingPeriod = renewalPeriod {
            _renewalPeriod = ObservedObject(initialValue: existingPeriod)
        } else {
            let newPeriod = RenewalPeriod(context: dataController.container.viewContext)
            _renewalPeriod = ObservedObject(initialValue: newPeriod)
        }
        
        self.dataController = dataController
    }
    
}


// MARK: - Preview
struct RenewalPeriodView_Previews: PreviewProvider {
    static var previews: some View {
        RenewalPeriodView(renewalPeriod: .example, dataController: DataController())
    }
}

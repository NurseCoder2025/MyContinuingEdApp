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
    @EnvironmentObject var dataController: DataController
    @ObservedObject var renewalPeriod: RenewalPeriod
    
    // Property to indicate whether the view is showing a completely new
    // renewal period that the user is adding or not
    @State var addingNewRenewalPeriod: Bool = false
    
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
                if addingNewRenewalPeriod {
                    Text("Add New Renewal Period")
                        .font(.largeTitle)
                } else  {
                    Text(renewalPeriod.renewalPeriodName)
                        .font(.largeTitle)
                }
            }//: VSTACK
            
            Spacer()
            
            VStack {
                Group {
                    Text("Enter the date the renewal period begins:")
                        .font(.headline)
                    Text("If you don't know the exact date, enter January 1st of the starting year")
                        .font(.caption)
                    Divider()
                    DatePicker(
                        "Starting Date",
                        selection: $renewalPeriod.renewalPeriodStart,
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
                        selection: $renewalPeriod.renewalPeriodEnd,
                        displayedComponents: .date
                    )
                    .padding([.leading, .trailing], 35)
                    .padding(.bottom, 20)
                } //: GROUP
                
                
                Button {
                    dataController.save()
                    dismiss()
                } label: {
                    Text("Save & Dismiss")
                }
                .buttonStyle(.borderedProminent)
                
                
            }//: VSTACK
            
            .onReceive(renewalPeriod.objectWillChange) { _ in
                dataController.queueSave()
            }
            .onChange(of: renewalPeriod.periodStart) { _ in
                addingNewRenewalPeriod = false
                dataController.assignActivitiesToRenewalPeriod()
            }
            .onChange(of: renewalPeriod.periodEnd) { _ in
                addingNewRenewalPeriod = false
                dataController.assignActivitiesToRenewalPeriod()
            }
            
    
            
            
        }//: NAV STACK
    } //: BODY
}


// MARK: - Preview
struct RenewalPeriodView_Previews: PreviewProvider {
    static var previews: some View {
        RenewalPeriodView(renewalPeriod: .example)
    }
}

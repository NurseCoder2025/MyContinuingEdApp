//
//  RenewalPeriodDatesView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: Display the UI controls that allow the user to enter the start and ending dates
// of a given renewal period object.

import SwiftUI

struct RenewalPeriodDatesView: View {
    // MARK: - PROPERTIES
    
    // Bindings to parent view (RenewalPeriodView)
    @Binding var hasLateFee: Bool
    @Binding var lateFeeDate: Date
    @Binding var lateFeeAmount: Double
    @Binding var periodStart: Date
    @Binding var periodEnd: Date
    
    // MARK: - BODY
    var body: some View {
        
        // MARK: - Renewal START
            VStack(spacing: 20){
                // MARK: - LATE FEE INFO
                GroupBox(
                    label: GroupBoxLabelView(labelText: "Late Fee Info", labelImage: "dollarsign")
                ) {
                    VStack {
                        Toggle(isOn: $hasLateFee) {
                            Text("Late fee charged for renewing after a certain date?")
                                .padding(.leading, 10)
                        }//: TOGGLE
                        if hasLateFee {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.yellow.opacity(0.2))
                                    .frame(width: 325, height: 75)
                                    .accessibilityHidden(true)
                                
                                VStack {
                                    DatePicker("Late Fee Starts", selection: $lateFeeDate, displayedComponents: .date)
                                        .bold()
                                    HStack {
                                        Text("Late Fee:")
                                        TextField("Late Fee Amount:", value: $lateFeeAmount, formatter: currencyFormatter)
                                            .keyboardType(.decimalPad)
                                            .foregroundStyle(.red)
                                    }//: HSTACK
                                }//: VSTACK
                                .padding(.horizontal, 20)
                                .frame(width: 325, height: 75)
                                
                            }//: ZSTACK
                        }//: IF
                    }//: VSTACK
                }//: GROUPBOX
                .frame(minWidth: 375, minHeight: 75)
                
                // MARK: - RENEWAL Dates
                GroupBox(
                    label: GroupBoxLabelView(labelText: "Renewal Dates", labelImage: "calendar.circle.fill")
                ) {
                    // Start Date
                    VStack {
                        Text("Enter the date the renewal period begins:")
                            .font(.headline)
                        Text("If you don't know the exact date, enter January 1st of the starting year")
                            .font(.caption)
                        DatePicker(
                            "Starting Date",
                            selection: $periodStart,
                            displayedComponents: .date
                        )
                        .padding(.horizontal, 40)
                        
                    }//: VSTACK
                
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    // End Date
                    VStack {
                        Text("Enter the date your renewal period ends:")
                            .font(.headline)
                        Text("If you don't know the exact date, enter the last day of the month in which the renewal ends of the respective year.")
                            .font(.caption)
                        DatePicker(
                            "Ending Date",
                            selection: $periodEnd,
                            displayedComponents: .date
                        )
                        .padding(.horizontal, 40)
                    }//: VSTACK
                   
                    
                }//: GROUPBOX
                .frame(minWidth: 375, minHeight: 75)
            }//: VSTACK
        
      
    }//: BODY
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RenewalPeriodDatesView(
        hasLateFee: .constant(true),
        lateFeeDate: .constant(Date.renewalLateFeeStartDate),
        lateFeeAmount: .constant(50.00),
        periodStart: .constant(Date.renewalStartDate),
        periodEnd: .constant(Date.renewalEndDate)
    )
}

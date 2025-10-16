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
    @Binding var lateFeeDate: Date
    @Binding var lateFeeAmount: Double
    @Binding var periodStart: Date
    @Binding var periodEnd: Date
    
    // MARK: - BODY
    var body: some View {
        
        // MARK: - Renewal START
        Group {
            VStack{
                // MARK: - LATE FEE INFO
                Group {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.yellow.opacity(0.2))
                            .frame(width: 325, height: 75)
                            .accessibilityHidden(true)
                            
                        VStack {
                            DatePicker("Late Fee Starts", selection: $lateFeeDate, displayedComponents: .date)
                                .padding(.trailing, 30)
                                .bold()
                            HStack {
                                Text("Late Fee:")
                                TextField("Late Fee Amount:", value: $lateFeeAmount, formatter: currencyFormatter)
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(.red)
                            }//: HSTACK
                        }//: VSTACK
                        .padding(.leading, 10)
                        
                    }//: ZSTACK
                }//: GROUP
                .frame(width: 325, height: 75)
                
                Text("Enter the date the renewal period begins:")
                    .font(.headline)
                Text("If you don't know the exact date, enter January 1st of the starting year")
                    .font(.caption)
                DatePicker(
                    "Starting Date",
                    selection: $periodStart,
                    displayedComponents: .date
                )
                .padding([.leading, .trailing], 35)
            }//: VSTACK
            .padding(.bottom, 10)
        }//: GROUP
        
        Divider()
        
        // MARK: - Renewal ENDS
        Group {
            VStack {
                Text("Enter the date your renewal period ends:")
                    .font(.headline)
                Text("If you don't know the exact date, enter the last day of the month in which the renewal ends of the respective year.")
                    .font(.caption)
                    .padding([.leading, .trailing], 30)
                DatePicker(
                    "Ending Date",
                    selection: $periodEnd,
                    displayedComponents: .date
                )
                .padding([.leading, .trailing], 35)
                .padding(.bottom, 20)
            }//: VSTACK
            .padding(.top, 10)
        } //: GROUP
    }
    
}

// MARK: - PREVIEW
#Preview {
    RenewalPeriodDatesView(
        lateFeeDate: .constant(Date.renewalLateFeeStartDate),
        lateFeeAmount: .constant(50.00),
        periodStart: .constant(Date.renewalStartDate),
        periodEnd: .constant(Date.renewalEndDate)
    )
}

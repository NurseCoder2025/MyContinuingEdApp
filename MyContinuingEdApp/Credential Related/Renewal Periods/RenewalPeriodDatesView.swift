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
    @Binding var periodBeginsOn: Date
    @Binding var renewalCompletedOn: Date
    @Binding var renewalCompleted: Bool
    
    // MARK: - BODY
    var body: some View {
        
        // MARK: - Renewal START
            VStack(spacing: 20){
                // MARK: - RENEWAL Dates
                GroupBox(
                    label: GroupBoxLabelView(labelText: "Renewal Dates", labelImage: "calendar.circle.fill")
                ) {
                    // Start Date
                    VStack {
                        Text("Enter the date the renewal period begins:")
                            .font(.headline)
                        Text("If you don't know the exact date, enter January 1st of the starting year for now, but check with your credential's issuer to get the correct date.")
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
                        
                        Text("If you don't know the exact date, enter December 31st of the next year for now, but be sure to get the correct date from the credential issuer as soon as you can.")
                            .font(.caption)
                        
                        DatePicker(
                            "Ending Date",
                            selection: $periodEnd,
                            displayedComponents: .date
                        )
                        .padding(.horizontal, 40)
                        
                        Text("Knowing this date is very important because if you don't renew your credential by the end of this day then it will lapse and you aren't legally able to use it again until it gets reinstated with the issuer.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                        
                    }//: VSTACK
                   
                    
                }//: GROUPBOX
                .frame(minWidth: 375, minHeight: 75)
                
                // MARK: - RENEWAL APPLICATION
                GroupBox(
                    label: GroupBoxLabelView(labelText: "Renewal Application", labelImage: "rectangle.and.pencil.and.ellipsis")
                ) {
                    VStack {
                        Text("The following items pertain to the renewal application process for the NEXT renewal period.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        DatePicker("Renewal Begins On:", selection: $periodBeginsOn, displayedComponents: [.date])
                        
                        Text("Enter the date when you can begin submitting the renewal application and any associated fees for the next renewal period. Check with your credential's issuer if unsure.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        // MARK: LATE FEE
                        VStack {
                            Toggle("Late Fee Charged?", isOn: $hasLateFee)
                            
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
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        // MARK: RENEWAL COMPLETION
                        Toggle("Renewed Credential?", isOn: $renewalCompleted)
                        
                        if renewalCompleted {
                            DatePicker("Date Renewed:", selection: $renewalCompletedOn, displayedComponents: [.date])
                        }//: IF
                    }//: VSTACK
                }//: GROUP BOX
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
        periodEnd: .constant(Date.renewalEndDate),
        periodBeginsOn: .constant(Date.renewalStartDate),
        renewalCompletedOn: .constant(Date.renewalEndDate),
        renewalCompleted: .constant(true)
    )
}//: PREVIEW

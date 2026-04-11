//
//  RenewalProgressSheet.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/14/25.
//

import SwiftUI

struct RenewalProgressSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    let renewal: RenewalPeriod
    
    let colors = ["blue", "purple", "green", "orange", "red", "cyan", "yellow"]
    
    // MARK: - COMPUTED PROPERTIES
    var allSpecialCats: [SpecialCategory] {
            let renewalCats = dataController.getAllSpecialCatsFor(renewal: renewal)
            return renewalCats
    }//: allSpecialCats
    
    var totalCEsRequired: Double {
        if let renewalCred = renewal.credential {
            // Ensure required is at least 1 to avoid division by zero and ProgressView errors
            return max(renewalCred.renewalCEsRequired, 1)
        } else {
            return 25.0
        }
    }
    
    /// Computed property that returns the number of CEs earned for a specific RenewalPeriod (whichever one
    /// was passed in to the RenewalProgressSheet initializer) as a formatted string value. If the Credential for
    /// the RenewalPeriod measures CEs in units vs clock hours, then the value will be converted into units.
    var totalCEsEarnedString: String {
        let earned = dataController.calculateRenewalPeriodCEsEarned(renewal: renewal)
        let amountEarned: Double
        let earnedString: String
        
        // Converting earned amount to units if the Credential measures CEs by units
        if let renewalCred = renewal.credential, renewalCred.measurementDefault == 2 {
            let earnedConverted = dataController.convertHoursToUnits(earned, for: renewal)
            amountEarned = max(earnedConverted, 0)
        } else {
            amountEarned = max(earned, 0)
        }
        
        earnedString = String(format: "%.2f", amountEarned)
        return earnedString
    }//: totalCEsEarnedString
    
    var totalCEsRemaining: Double {
       let clockHrsRemaining = dataController.calculateRemainingTotalCEsFor(renewal: renewal)
        
        // Converting hours to units IF Credential measures CEs in units vs hours
        if let renewalCred = renewal.credential, renewalCred.measurementDefault == 2 {
            let convertedHours = dataController.convertHoursToUnits(clockHrsRemaining, for: renewal)
            return convertedHours
        } else {
            return clockHrsRemaining
        }
    }//: totalCEsRemaining
    
    var monthsRemaining: Int {
        let calendar = Calendar.current
        let startDate = Date.now
        let endDate = renewal.renewalPeriodEnd
        
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return components.month ?? 0
        
    }//: monthsRemaining
    
    var cesNeededPerMonth: String {
        let remaining = totalCEsRemaining
        let months = monthsRemaining
        let cesPerMonth = remaining / Double(months)
        
        if cesPerMonth < 0 {
            return String(format: "%.2f", 0.00)
        }
        
        let answer = String(format: "%.2f", cesPerMonth)
        return answer
    }
    
    var daysUntilRenewal: String {
        let calendar = Calendar.current
        let today = Date.now
        let endDate = renewal.renewalPeriodEnd
        
        let components = calendar.dateComponents([.day], from: today, to: endDate)
        let days = components.day ?? 0
        
        let answer = String(format: "%i", days)
        return answer
        
    }//: daysUntilRenewal
    
    var getCEMeasurement: String {
        if let renewalCred = renewal.credential {
            if renewalCred.measurementDefault == 1 {
                return "hours"
            } else {
                return "units"
            }
        } else {
            return ""
        }
    }
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your CE Progress This Renewal")
                        .font(.title)
                        .bold()
                    Divider()
                    Group {
                        HStack {
                            Text("Overall CEs Earned")
                                .font(.title2)
                                .padding(.bottom, 5)
                            Spacer()
                            Text("\(totalCEsEarnedString)")
                                .bold()
                        }//: HSTACK
                        TotalRenewalProgressBar(renewal: renewal)
                            .frame(width: 350, height: 25)
                    }//: GROUP
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    
                    HStack {
                        RenewalStatBoxView(
                            width: 200,
                            height: 100,
                            titleText: "CEs Needed Per Month:",
                            statValue: cesNeededPerMonth,
                            subscriptText: "To meet the \(totalCEsRequired) \(getCEMeasurement) required",
                            boxColor: Color.yellow,
                            textColor: nil
                        )
                        
                        RenewalStatBoxView(
                            width: 150,
                            height: 100,
                            titleText: "Days To Renew:",
                            statValue: daysUntilRenewal,
                            subscriptText: "Clock is ticking!",
                            boxColor: Color.cyan,
                            textColor: .white
                        )
                        
                    }//: HSTACK
                    .padding(.bottom, 10)
                    
                    Divider()
                        .padding(.bottom, 10)
                    
                    ScrollView {
                        LazyVStack {
                            if allSpecialCats.isEmpty {
                                NoItemView(
                                    noItemTitleText: "No Special CE Categories To Track",
                                    noItemMessage: "Currently, there are no special CE categories like ethics assigned to this credential.  However, if you are required to get so many CEs in a particular area(s) for each renewal, be sure to go to the credential's information sheet and add them.",
                                    noItemImage: "tag.slash.fill"
                                )
                            } else {
                                Group {
                                    Text("Required CE \(allSpecialCats.count == 1 ? "Category" : "Categories") Progress")
                                        .font(.title2).bold()
                                        .padding(.bottom, 10)
                                    ForEach(allSpecialCats) { specialCat in
                                        VStack(spacing: 0) {
                                            Text(specialCat.labelText)
                                                .bold()
                                            SpecialCatProgressView(
                                                renewal: renewal,
                                                specialCat: specialCat,
                                                color: colors.randomElement()
                                            )
                                        }//: VSTACK
                                        .padding(.bottom, 5)
                                    }//: LOOP
                                }//: GROUP
                            }//: IF ELSE
                        }//: LAZY V STACK
                    }//: SCROLL VIEW
                } //: VSTACK
                .padding()
                // MARK: - TOOLBAR
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Dismiss")
                        }//: BUTTON
                    }//: TOOLBAR ITEM (dismiss)
                }//: TOOLBAR
        }//: NAV VIEW
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RenewalProgressSheet(renewal: .example)
        .environmentObject(DataController(inMemory: true))
}

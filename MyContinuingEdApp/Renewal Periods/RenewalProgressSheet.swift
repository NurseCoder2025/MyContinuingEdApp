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
    
    // Passing in a Filter data type because, in SidebarCredentialsSectionView, that is what is being passed in
    // with the ForEach closure.  Since each Filter has a renewalPeriod property, that can be easily accessed.
    let renewalFilter: Filter
    
    let colors = ["blue", "purple", "green", "orange", "red", "cyan", "yellow"]
    
    // MARK: - COMPUTED PROPERTIES
    var allSpecialCats: [SpecialCategory] {
        if let renewal = renewalFilter.renewalPeriod {
            let renewalCats = dataController.getAllSpecialCatsFor(renewal: renewal)
            return renewalCats
        }//: IF LET
        return []
    }//: allSpecialCats
    
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            Text("Your CE Progress This Renewal")
                .font(.title)
                .bold()
            Divider()
            
            ScrollView {
                LazyVStack {
                    Group {
                        Text("Overal CEs Earned")
                            .font(.title2).bold()
                            .padding(.bottom, 5)
                        
                        if let renewal = renewalFilter.renewalPeriod {
                            RenewalProgressView(renewal: renewal)
                        }
                    }//: GROUP
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
                            
                            if let renewal = renewalFilter.renewalPeriod {
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
                            }//: IF LET
                        }//: GROUP
                    }//: IF ELSE
                    
                }//: LAZY V STACK
            }//: SCROLLVIEW
            
        }//: NAV STACK
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
       
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    let sampleFilter = Filter(name: "Test Filter", icon: "chart.bar.xaxis")
    RenewalProgressSheet(renewalFilter: sampleFilter)
}

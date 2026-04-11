//
//  ReinstatementCEProgressView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/12/26.
//

import SwiftUI

struct ReinstatementCEProgressView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    let reinstatement: ReinstatementInfo
    let requiredHours: Double
    let earnedHours: Double
    
    let columns = Array(repeating: GridItem(.adaptive(minimum: 25, maximum: 250), spacing: 5.0), count: 2)
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property which gets a dictionary of all ReinstatementSpecialCats assigned
    /// to this reinstatement which have NOT yet been completed.
    var specialCatsUncompleted: [ReinstatementSpecialCat:Double] {
        if let renewal = reinstatement.renewal {
            return dataController.getOutstandingSpecialCatsForReinstatement(renewal: renewal)
        } else {
            return [:]
        }
    }//: specialCatsUncompleted
    
    /// Computed property returning an array of all keys in the specialCatsUncompleted dictionary.
    ///
    /// This property is used primarily for the ForEach loop in the Special Category section of the
    /// ReinstatementCEProgressView so that the correct number of SpecialCatHrsNeededCardViews can be
    /// shown, if any.
    var specialCatsToShow: [ReinstatementSpecialCat] {
        var catArray: [ReinstatementSpecialCat] = []
        for specCat in specialCatsUncompleted.keys {
            catArray.append(specCat)
        }//: LOOP
        return catArray
    }//: specialCatsToShow
    
    // MARK: - BODY
    var body: some View {
        Section {
            VStack {
                // MARK: Total Progress
                Group {
                    Text("CE Progress Towards Reinstatement")
                        .font(.headline)
                    
                    Divider()
                    
                    ReinstatementStandAloneProgressView(
                        reinstatement: reinstatement,
                        requiredHours: requiredHours,
                        earnedHours: earnedHours
                    )
                }//: GROUP
                
                // MARK: Special CAT Progress
                if specialCatsToShow.isNotEmpty {
                    Group {
                        VStack {
                            Divider()
                            Text("You Still Need To Complete CEs in the following Categories:")
                                .padding(.vertical, 5)
                                .font(.headline)
                            
                            LazyVGrid(columns: columns) {
                                ForEach(specialCatsToShow) { cat in
                                    SpecialCatHrsNeededCardView(
                                        specCat: cat,
                                        hoursNeeded: specialCatsUncompleted[cat] ?? 999.99
                                    )
                                }//: LOOP
                            }//: LAZY V GRID
                        }//: VSTACK
                    }//: GROUP
                    .padding(.horizontal, 10)
                    
                }//: IF
            }//: VSTACK
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(Color(.gray).opacity(0.3))
            )
        }//: SECTION
    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    let _ = controller.createSampleCredential()
    let sampleRenewal = controller.createSampleRenewalPeriod(reinstateYN: true)
    
    if let reinstatement = sampleRenewal.reinstatement {
        ReinstatementCEProgressView(
            reinstatement: reinstatement,
            requiredHours: 25.0,
            earnedHours: 5.0
        )
        .environmentObject(controller)
    }//: IF LET
   
}//: PREVIEW

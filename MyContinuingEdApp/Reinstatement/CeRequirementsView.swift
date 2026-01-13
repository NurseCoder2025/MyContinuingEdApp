//
//  CeRequirementsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct CeRequirementsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var reinstatement: ReinstatementInfo
    
    @State private var reinstateCEHrRequired: Double = 1.0
    @State private var reinstateCEHrEarned: Double = 0.0
    
    @State private var requiredCECats: [ReinstatementSpecialCat] = []
    @State private var showAddRequiredCatsRows: Bool = false
    @State private var showNoCatsToAddView: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var credCEMeasurement: String {
        if let cred = reinstatement.lapsedCredential {
            switch cred.measurementDefault {
            case 1:
                return "hours"
            default:
                return "units"
            }//: SWITCH
        } else {
            return "hours"
        }
    }//: credCEMeasurement
    
    // MARK: - CLOSURES
    /// Closure for passing up the closure in RSCRowView to ReinstatementInfoSheet where the SpecialCatManagementSheet will be presented.
    var addSpecialCategory: () -> Void
    
    // MARK: - BODY
    var body: some View {
        // MARK: TOTAL HOURS
        Section {
            HStack(spacing: 45) {
                Text("Total Extra \(credCEMeasurement.uppercased()) Required:")
                    .bold()
                
                TextField(
                    "CEs Required",
                    value: $reinstatement.totalExtraCEs,
                    formatter: ceHourFormatter
                )//: TEXTFIELD
                .frame(maxWidth: 50)
                .keyboardType(.decimalPad)
                .onSubmit {
                    dismissKeyboard()
                }//: ON SUBMIT
            }//: HSTACK
            .frame(maxWidth: .infinity, alignment: .leading)
        } header: {
            Text("Required CEs")
        } footer: {
            Text("Whenever you complete a CE activity be sure to toggle the 'Reinstatement CE' switch on the activity page so that the app can keep track of your progress in meeting the reinstatement requirement.")
        }//: SECTION
        
        // MARK: Credential-Specific Requirements
        Section {
            VStack {
                Text("As part of the total number of CEs that you need to get, your credential issuer may also require you to get a certain number of CEs in a certain area or topic. If that's the case, use this section to track the requirements.")
                    .font(.caption)
                
                Button {
                    addSpecialCERequirement()
                } label: {
                    Text("Add Specific CE Requirement")
                }//: BUTTON
                .buttonStyle(.borderedProminent)
            }//: VSTACK
            
            if showNoCatsToAddView {
                NoSpecialCatsToAddView(createSpecialCategory: {
                    addSpecialCategory()
                })
            } else if showAddRequiredCatsRows {
                ForEach(requiredCECats) { cat in
                    RSCRowView(rscItem: cat)
                    // TODO: Is a Divider needed here?
                }//: LOOP
            }//: IF ELSE
            
        } header: {
            Text("Credential-Specific CE Requirements")
        } footer: {
            Text("Any CE amounts listed in this section are assumed to be part of the total number specified in the top section that are required for reinstatement.")
        } //: SECTION
        .onChange(of: reinstatement.requiredSpecialCatHours) { _ in
            removeSpecialCERequirement()
        }//: ON CHANGE
        
        // MARK: CE COMPLETION
        Section("CE Completion") {
            ReinstatementCEProgressView(
                reinstatement: reinstatement,
                requiredHours: reinstateCEHrRequired,
                earnedHours: reinstateCEHrEarned
            )
            
            if reinstatement.cesCompletedYN {
                DatePicker("Date Completed", selection: $reinstatement.riCEsCompletedDate, displayedComponents: .date)
            }//: IF
               
        }//: SECTION
         // MARK: - ON APPEAR
         .onAppear {
             if let renewal = reinstatement.renewal {
                 let reinstateHours = dataController.calculateCEsForReinstatement(renewal: renewal)
                 reinstateCEHrRequired = reinstateHours.required
                 reinstateCEHrEarned = reinstateHours.earned
             }//: IF LET
         }//: ON APPEAR
        
    }//: BODY
     // MARK: - METHODS
    /// Method for adding a new RSCRowView to the CeRequirementsView by creating a new
    /// ReinstatementSpecialCat object, assigning it to the reinstatement object, and then adding it to the
    /// internal array.
    private func addSpecialCERequirement() {
        guard let probCred = reinstatement.lapsedCredential, probCred.allSpecialCats.isNotEmpty else {
            showAddRequiredCatsRows = false
            showNoCatsToAddView = true
            return
        }
        
        let newRequirement = dataController.createNewRSCItemFor(reinstatement: reinstatement)
        requiredCECats.append(newRequirement)
        showAddRequiredCatsRows = true
    }//: addSpecialCERequirement()
    
    /// Method for removing a RSCRowView from the CeRequirementsView by removing any ReinstatementSpecialCat object
    /// that is no longer part of the ReinstatementInfo's rscItems property.
    ///
    /// It should be noted that the method assigns a transformed copy of the rcsItems property as a Set to a constant for
    /// more efficient comparison.  Should an element in the requiredCECats array not be present in that set, then its index
    /// is saved to a constant and passed to the .remove(at: ) method for removal.
    private func removeSpecialCERequirement() {
        let savedRequirements = Set(reinstatement.requiredSpecialCatHours)
        for requirement in requiredCECats {
            if savedRequirements.doesNOTContain(requirement), let index = requiredCECats.firstIndex(of: requirement) {
                requiredCECats.remove(at: index)
            }//: IF LET
        }//: LOOP
    }//: removeSpecialCERequirement()
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CeRequirementsView(reinstatement: .example, addSpecialCategory: {})
}

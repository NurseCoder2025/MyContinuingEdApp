//
//  AwardsView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/24/25.
//

import SwiftUI

struct AwardsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // Award related properties
    @State private var selectedAward: Award = .example
    @State private var showingAwardDetails: Bool = false
    var awardTitle: String {
        if dataController.hasEarned(award: selectedAward) {
            return "Unlocked: \(selectedAward.name)"
        } else {
            return "Locked"
        }
    }
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 100))]
    }
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(Award.allAwards) { award in
                        Button {
                            selectedAward = award
                            showingAwardDetails = true
                        } label: {
                            Image(systemName: award.image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 100, height: 100)
                                .foregroundColor(dataController.hasEarned(award: award) ? Color(award.color) : .secondary.opacity(0.5))
                        }
                        .accessibilityLabel(dataController.hasEarned(award: award) ? "\(award.name)" : "Locked")
                        .accessibilityHint(award.description)
                        
                        
                        
                    } //: LOOP
                } //: LAZY V GRID
                
            }//: SCROLL VIEW
            .navigationTitle("CE Achievements")
        } //: NAV VIEW
        
        .alert(awardTitle, isPresented: $showingAwardDetails) {
        } message: {
            Text(selectedAward.description)
        }
       
        
    }//: BODY
}


// MARK: - PREVIEW
struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}

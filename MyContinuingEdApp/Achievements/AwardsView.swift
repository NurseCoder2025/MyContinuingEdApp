//
//  AwardsView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/24/25.
//

import CoreData
import SwiftUI

struct AwardsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // Award related properties
    @State private var selectedAward: Achievement?
    @State private var showingAwardDetails: Bool = false
    
    // MARK: - CORE DATA
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allAchievements: FetchedResults<Achievement>
    // MARK: - COMPUTED PROPERTIES
    var awardTitle: String {
        if let award = selectedAward {
            if dataController.hasEarned(award: award) {
                return "Unlocked: \(award.achievementName)"
            } else {
                return "Locked"
            }
        } else {
            return "No Award Selected"
        }//: IF LET
    }//: awardTitle
    
    var earnedDate: String {
        if let award = selectedAward, let completedOn = award.dateEarned {
            return completedOn.formatted(date: .numeric, time: .omitted)
        } else {
            return ""
        }
    }//: earnedDate
    
    /// Computed property in AwardsView that returns a String composed of either the award's description and
    /// when it was earned on, just the award's description (if no date is available), or an empty string.
    var awardMessage: String {
        if let award = selectedAward, let desc = award.achievementDescript, let awardDate = award.dateEarned {
            return "\(desc)/n/nEarned on \(earnedDate)"
        } else if let award = selectedAward, let desc = award.achievementDescript {
            return "\(desc)"
        } else {
            return ""
        }
    }//: awardMessage
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 100))]
    }
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(allAchievements) { award in
                        Button {
                            selectedAward = award
                            showingAwardDetails = true
                        } label: {
                            VStack {
                                Image(systemName: award.achievementImage)
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .frame(width: 100, height: 100)
                                    .foregroundStyle(getAwardColor(award: award))
                                    .overlay(alignment: .bottom) {
                                        if let awardDate = award.dateEarned {
                                            // TODO: Adjust coloring
                                            Text(earnedDate)
                                                .bold()
                                                .foregroundStyle(.secondary)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.black.opacity(0.3))
                                                        .padding()
                                                )
                                        }//: IF LET
                                    }//: OVERLAY
                            }//: VSTACK
                        }//: BUTTON
                        .accessibilityLabel(createAwardLabel(award: award))
                        .accessibilityHint(awardMessage)
                        
                    } //: LOOP
                } //: LAZY V GRID
                
            }//: SCROLL VIEW
            .navigationTitle("CE Achievements")
        } //: NAV VIEW
        
        .alert(awardTitle, isPresented: $showingAwardDetails) {
        } message: {
            Text(awardMessage)
        }
       
        
    }//: BODY
    // MARK: - FUNCTIONS
    
    /// AwardsView method that returns a specific ui Color depending on whether a given
    /// award argument has been earned as determined by the DataController hasEarned
    /// method.
    /// - Parameter award: Award object being passed in
    /// - Returns: Color depending on whether the award has been earned or not
    ///
    /// If the award has been earned, then the award's color property value will be returned
    /// as a Color, but if not then the Colo will be the secondary color with a 50% opacity.
    /// This method's return value is used to determine the foregroundStyle for the award
    /// Image.
    func getAwardColor(award: Achievement) -> Color {
        dataController.hasEarned(award: award) ? Color(award.achievementColor) : .secondary.opacity(0.5)
    }//: getAwardColor
    
    /// AwardsView method that returns a localized string value consisting of either the
    /// name of the Award object passed in or "Locked" if the award has not been earned yet.
    /// - Parameter award: Award object
    /// - Returns: Localized string value of either the award's name or "Locked"
    func createAwardLabel(award: Achievement) -> LocalizedStringKey {
        dataController.hasEarned(award: award) ? "\(award.achievementName)" : "Locked"
    }//: createAwardLabel
    
}//: STRUCT


// MARK: - PREVIEW
struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}

//
//  ContentViewToolbarView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/16/25.
//

// Purpose: To encapsulate two menus that take up a bunch of space but are not that complex of a view
// from the parent view (ContentView)

import CoreData
import SwiftUI

struct ContentViewToolbarView: View {
    // MARK: - PROPERTIES
    @Environment(\.spotlightCentral) var spotlightCentral
    @EnvironmentObject var dataController: DataController
    
    let allDateSortTypes: [SortType] = [.dateCompleted, .dateCreated, .dateModified]
    let hoursCostsSortTypes: [SortType] = [.awardedCEAmount, .activityCost]
    let allAlphabeticalSortTypes: [SortType] = [.format, .typeOfCE]
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
    // MARK: - BODY
    var body: some View {
        // MARK: Filter Menu
        Group {
            Menu {
                Button(dataController.filterEnabled ? "Turn filter off" : "Turn filter on") {
                    dataController.filterEnabled.toggle()
                } //: BUTTON
                
                Divider()
            
                Menu("Filter by") {
                    // Credential
                    // ONLY show the credential picker filter if there is more than 1 credential
                    if allCredentials.count > 1 {
                        Picker("Credential", selection: $dataController.filterCredential) {
                            ForEach(allCredentials) {cred in
                                Text(cred.credentialName).tag(cred.credentialName)
                            }//: LOOP
                        }//: PICKER
                        
                        Divider()
                    }//: IF
                    
                    // Activity Status
                    Picker("Activity Status", selection: $dataController.filterExpirationStatus) {
                        Text("All Activities").tag(ExpirationType.all)
                        Text("Currently Valid").tag(ExpirationType.stillValid)
                        Text("Expiring Soon").tag(ExpirationType.expiringSoon)
                        Text("Last Chance!").tag(ExpirationType.finalDay)
                        Text("Expired").tag(ExpirationType.expired)
                        Text("Completed").tag(ExpirationType.finishedActivity)
                    }//: Activity Status PICKER
                    .disabled(dataController.filterEnabled == false)
                    
                    Divider()
                    
                    // Activity Rating
                    Picker("Activity Rating", selection: $dataController.filterRating) {
                        Text("All").tag(-1)
                        Text(ActivityRating.terrible.rawValue).tag(0)
                        Text(ActivityRating.poor.rawValue).tag(1)
                        Text(ActivityRating.soSo.rawValue).tag(2)
                        Text(ActivityRating.interesting.rawValue).tag(3)
                        Text(ActivityRating.lovedIt.rawValue).tag(4)
                    }//: Activity Rating PICKER
                    .disabled(dataController.filterEnabled == false)
                    
                }//: FILTERS MENU
                
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .symbolVariant(dataController.filterEnabled ? .fill : .none)
            } //: MENU + label
            
        }//: GROUP
        
        // MARK: SORT MENU
        Group {
            Menu {
                // MARK: Name Submenu
                Group {
                    Picker("Name", selection: $dataController.sortType) {
                        Text("CE Name").tag(SortType.name)
                    }//: PICKER for name
                     // Name Order Picker
                    Picker("Order by", selection: $dataController.sortNewestFirst) {
                        Text("A to Z").tag(true)
                        Text("Z to A").tag(false)
                    } // PICKER for name order
                    .disabled(dataController.sortType != .name)
                }//: GROUP (Name Submenu)
                
                // MARK: Date Submenu
                Group {
                    Menu("Date") {
                        Picker("Sort by", selection: $dataController.sortType) {
                            Text("Date Created").tag(SortType.dateCreated)
                            Text("Date Modified").tag(SortType.dateModified)
                            Text("Date Completed").tag(SortType.dateCompleted)
                        } //: PICKER
                        
                        Divider()
                        // Date Order Picker
                        Picker("Order by", selection: $dataController.sortNewestFirst) {
                            Text("Newest to Oldest").tag(true)
                            Text("Oldest to Newest").tag(false)
                        }
                        .disabled(!allDateSortTypes.contains(dataController.sortType))
                        
                    }//: Date Sub-Menu
                }//: GROUP
                
                // MARK: CE Hours/Cost Submenu
                Group {
                    Menu("CE Amount & Cost") {
                        Picker("Hours and cost", selection: $dataController.sortType) {
                            Text("Cost").tag(SortType.activityCost)
                            Text("CE Earned").tag(SortType.awardedCEAmount)
                        } //: Hours and cost PICKER
                        Divider()
                        
                        Picker("Sort order", selection: $dataController.sortNewestFirst) {
                            Text("Lowest to Highest").tag(true)
                            Text("Highest to Lowest").tag(false)
                        } //: Sort Order PICKER
                        .disabled(!hoursCostsSortTypes.contains(dataController.sortType))
                        
                    }//: Numbers submenu
                }//: GROUP
                
                // MARK: CE Type/Format Submenu
                Group {
                    Menu("CE Type & Format") {
                        Picker("CE type and format", selection: $dataController.sortType) {
                            Text("CE type").tag(SortType.typeOfCE)
                            Text("Format").tag(SortType.format)
                        }//: PICKER
                        
                        Divider()
                        
                        Picker("Sort order", selection: $dataController.sortNewestFirst) {
                            Text("A to Z").tag(true)
                            Text("Z to A").tag(false)
                        } //: Sort Order PICKER
                        .disabled(!allAlphabeticalSortTypes.contains(dataController.sortType))
                    }//: MENU (CE Type/Format)
                }//: GROUP
                
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down.circle")
            } //: MENU - Sort By
            
        }//: Group
        
        // MARK: ADD ACTIVITY
        Group {
            Button {
                if #available(iOS 17, *) {
                    // Use the dataController's createActivity method and item
                    // will be automatically added to Spotlight's index
                    dataController.createActivity()
                } else {
                    // Manually add CeActivity to Spotlight's index
                    let newCe = dataController.createNewCeActivityIOs16()
                    spotlightCentral?.addCeActivityToDefaultIndex(newCe)
                }
            } label: {
                Label("New Activity", systemImage: "square.and.pencil")
            }
        }//: GROUP
        
    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    ContentViewToolbarView()
}

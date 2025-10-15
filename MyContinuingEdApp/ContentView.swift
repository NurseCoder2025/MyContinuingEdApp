//
//  ContentView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController
    
    let allDateSortTypes: [SortType] = [.dateCompleted, .dateCreated, .dateModified]
    let hoursCostsSortTypes: [SortType] = [.awardedCEAmount, .activityCost]
    let allAlphabeticalSortTypes: [SortType] = [.format, .typeOfCE]
    
    // Properties for warning users about deleting a CE activity
    @State private var showDeleteWarning: Bool = false
    @State private var activityToDelete: CeActivity?
    let activityDeleteWarning: String = "WARNING: You are about to delete a CE activity along with any reflections attached to it.  Are you sure you want to delete?  This cannot be undone."
    
    
    // MARK: - BODY
    var body: some View {
            /// The List section navigates to the ActivityROW and not the ActivityView. The
            /// ActivityView struct is for showing the details of each activity.
            List(selection: $dataController.selectedActivity) {
                ForEach(dataController.activitiesForSelectedFilter()) { activity in
                    ActivityRow(activity: activity)
                } //: LOOP
                .onDelete(perform: delete)
                
            } //: LIST
            .navigationTitle("CE Activities")
            .searchable(text: $dataController.filterText, tokens: $dataController.filterTokens, suggestedTokens:  .constant(dataController.suggestedFilterTokens), prompt: "Filter CE activities, or type # to add tags") { tag in
                Text(tag.tagTagName)
            }
            .alert("CE Activity Deletion Warning", isPresented: $showDeleteWarning) {
                Button("Delete", role: .destructive) {
                    if let activity = activityToDelete {
                        dataController.delete(activity)
                    }
                    activityToDelete = nil
                } //: DELETE button
                
                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                }
            } message: {
                Text(activityDeleteWarning)
            }
            // MARK: - TOOLBAR
            .toolbar {
                // MARK: Filter
                Menu {
                    Button(dataController.filterEnabled ? "Turn filter off" : "Turn filter on") {
                        dataController.filterEnabled.toggle()
                    } //: BUTTON
                    
                    Divider()
                    
                    // MARK: - SORT
                    Menu("Sort by") {
                        // Name
                        Picker("Name", selection: $dataController.sortType) {
                            Text("CE Name").tag(SortType.name)
                        }//: PICKER for name
                        // Name Order Picker
                        Picker("Order by", selection: $dataController.sortNewestFirst) {
                            Text("A to Z").tag(true)
                            Text("Z to A").tag(false)
                        } // PICKER for name order
                        .disabled(dataController.sortType != .name)
                        
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
                            
                        }//: OTHER SORTS MENU
                        
                    }//: MENU - Sort By
                    // MARK: - FILTERS
                    Menu("Filter by") {
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
                
                Button(action: dataController.createActivity) {
                    Label("New Activity", systemImage: "square.and.pencil")
                }
                
                
            } //: TOOLBAR
        
    } //: BODY
    
    // MARK: - ContentView Methods
    func delete(_ offsets: IndexSet) {
        let activities = dataController.activitiesForSelectedFilter()
        
        for offset in offsets {
            let item = activities[offset]
            activityToDelete = item
        }
        
        showDeleteWarning = true
    } //: DELETE Method
    
    
}


// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

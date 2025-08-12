//
//  SidebarView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI

struct SidebarView: View {
    // MARK: - PROPERTIES
    // Accessing the data controller environmental object
    @EnvironmentObject var dataController: DataController
    
    // MARK: renaming tags
    @State private var showRenamingAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var tagToRename: Tag?
    
    // Properties for editing renewal periods
    @State private var renewalToEdit: RenewalPeriod?
    @State private var newRenewal: RenewalPeriod?
    
    // MARK: deleting renewal periods
    @State private var showDeletingRenewalAlert: Bool = false
    @State private var renewalToDelete: RenewalPeriod?
    
    // Property for displaying the Awards sheet
    @State private var showAwardsSheet: Bool = false
    
    // Property for displaying the half-screen Renewal Period entry screen
    @State private var showRenewalPeriodView: Bool = false
    
    // Property for indicating whether a new renewal period is being added
    @State private var isAddingNewRenewal: Bool = false
    
    // Defining smart filters
    let smartFilters: [Filter] = [.allActivities, .recentActivities]
    
    // Converting all fetched tags to Filter objects
    var convertedTagFilters: [Filter] {
        tags.map { tag in
            Filter(name: tag.tagTagName, icon: "tag", tag: tag)
        }
    }
    
    // Converting all fetched renewal periods to Filter objects
    var convertedRenewalFilters: [Filter] {
        renewals.map { renewal in
            Filter(name: renewal.renewalPeriodName, icon: "timer.square", renewalPeriod: renewal)
        }
    }
    
    
    // MARK: - Core Data fetch requests
    // All tags sorted by name
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tagName)]) var tags: FetchedResults<Tag>
    
    // Retrieving all saved renewal periods
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodName)]) var renewals: FetchedResults<RenewalPeriod>
    
    // MARK: - BODY
    var body: some View {
        List(selection: $dataController.selectedFilter) {
            // MARK: SMART FILTERS
            Section("Smart Filters") {
                ForEach(smartFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                    } //: NAV LINK
                    
                } //: LOOP
            } //: SECTION (smart filters)
            
            // MARK: TAGS
            Section {
                ForEach(convertedTagFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                            .badge(filter.tag?.tagActiveActivities.count ?? 0)
                            .contextMenu {
                                Button {
                                    renameTag(filter)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }//: CONTEXT MENU
                        
                    } //: NAV LINK
                } //: LOOP
                .onDelete(perform: delete)
                
            } header: {
                HStack {
                    Text("Tags")
                    Spacer()
                    
                    // New tag creation button
                    Button{
                        dataController.createNewTag()
                    } label: {
                        Label("New tag", systemImage:"plus")
                            .labelStyle(.iconOnly)
                    }
                    .padding(.trailing, 20)
                  
                    
                } //: HSTACK
                
            } //: SECTION (tags)
            
            // MARK: RENEWAL PERIODS
            Section {
                ForEach(convertedRenewalFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                            .badge(filter.renewalPeriod?.renewalCurrentActivities.count ?? 0)
                            .contextMenu {
                                Button {
                                    isAddingNewRenewal = false
                                    editRenewalPeriod(filter)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                    } //: NAV LINK
                    
                }//: LOOP
                .onDelete(perform: deleteRenewalPeriod)
                
            } header: {
                HStack {
                    Text("Renewal Periods")
                        .font(.subheadline)
                    Spacer()
                    
                        Button {
                            newRenewal = dataController.createRenewalPeriod()
                            isAddingNewRenewal = true
                            showRenewalPeriodView = true
                        } label: {
                            Label("New renewal", systemImage:"plus")
                                .labelStyle(.iconOnly)
                        }
                        .padding(.trailing, 20)
                       
                    
                    
                } //: HSTACK
            }//: SECTION (renewal periods)
            
            
            
        } //: LIST
        // Adding this code to prevent a stale state between times
        // when the user decides to edit a renewal period
        .onChange(of: showRenewalPeriodView) {isPresented in
            if !isPresented {
                renewalToEdit = nil
                newRenewal = nil
            }
            
        }  // ON CHANGE
        
        // MARK: Toolbar
        .toolbar {
            // Awards sheet toggle button
            Button {
                showAwardsSheet.toggle()
            } label: {
                Label("Show awards", systemImage: "rosette")
            }
            
#if DEBUG
            Button {
                dataController.deleteAll()
                dataController.createSampleData()
            } label: {
                Label("Add Samples", systemImage: "flame")
            }
#endif
            
        } //: TOOLBAR
        // MARK: Alerts & Sheets
        .alert("Rename Tag", isPresented: $showRenamingAlert) {
            Button("OK", action: confirmTagRename)
            Button("Cancel", role: .cancel) {}
            TextField("New tag name:", text: $newTagName)
        } //: ALERT
        .alert("Warning: Deleting Renewal Period", isPresented: $showDeletingRenewalAlert) {
            Button("Delete", role: .destructive ) {
                if let renewal = renewalToDelete {
                    dataController.delete(renewal)
                }
                renewalToDelete = nil
            } //: Delete button
            Button("Cancel", role: .cancel) {
                renewalToDelete = nil
            } //: Cancel button
        } message: {
            Text("You are about to delete the \(renewalToDelete?.renewalPeriodName ?? "selected") renewal period. This ONLY removes the renewal period and NOT the CE Activities assigned to it. This action cannot be undone.")
        }//: ALERT
        .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
        .sheet(isPresented: $showRenewalPeriodView){
            if let renewal = isAddingNewRenewal ? newRenewal : renewalToEdit {
                RenewalPeriodView(
                    renewalPeriod: renewal,
                    addingNewRenewalPeriod: isAddingNewRenewal
                )
                .presentationDetents([.medium])
            }
                
        }//: SHEET
        
        
    } //: BODY
    
    // MARK: - View Functions
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = tags[offset]
            dataController.delete(item)
        }
    } //: DELETE method
    
    func renameTag(_ selectedFilter: Filter) {
        tagToRename = selectedFilter.tag
        newTagName = selectedFilter.name
        showRenamingAlert = true
    }
    
    func confirmTagRename() {
        tagToRename?.tagName = newTagName
        dataController.save()
    }
    
    // Function for editing a renewal period
    /// This function assigns the passed-in filter (renewal period object) to the renewalToEdit
    ///  @State variable for use in a sheet presentation. It also triggers the sheet's presentation
    ///  by changing the showRenewalPeriod property to true.
    /// - Parameter selectedFilter: RenewalPeriod object as selected by the user
    func editRenewalPeriod(_ selectedFilter: Filter) {
        guard let renewal = selectedFilter.renewalPeriod, renewals.contains(renewal) else {return}
        
        renewalToEdit = selectedFilter.renewalPeriod
        showRenewalPeriodView = true
    }
    
    // Function for deleting a renewal period
    func deleteRenewalPeriod(_ offsets: IndexSet) {
        if let selectedPeriodIndex = offsets.first {
            renewalToDelete = renewals[selectedPeriodIndex]
            showDeletingRenewalAlert = true
        }
    }
        
    } //: STRUCT
    

// MARK: - PREVIEW
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(DataController.preview)
    }
}

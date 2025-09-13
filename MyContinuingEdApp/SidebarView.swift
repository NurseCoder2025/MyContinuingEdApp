//
//  SidebarView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/9/25.
//

import SwiftUI

// The primary (initial) view when first launching the app. Provides different ways of filtering
// CE activities that have been entered: via 2 "smart" filters, user-created tags, and by
// credential-renewal cycle.

struct SidebarView: View {
    // MARK: - PROPERTIES
    // Accessing the data controller environmental object
    @EnvironmentObject var dataController: DataController
    
    // MARK: Renaming tags
    @State private var showRenamingAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var tagToRename: Tag?
    
    // MARK: Properties for editing renewal periods
    @State private var renewalToEdit: RenewalPeriod?
    
    
    // MARK: Deleting renewal periods
    @State private var showDeletingRenewalAlert: Bool = false
    @State private var renewalToDelete: RenewalPeriod?
    
    // MARK: Credentials
    @State private var showCredentialListView: Bool = false  // show ALL entered credentials
    @State private var showCredentialSheet:Bool = false // for adding a brand new credential only
    
    // MARK: Property for displaying the Awards sheet
    @State private var showAwardsSheet: Bool = false
    
    // Property for displaying the half-screen Renewal Period entry screen
    @State private var showRenewalPeriodView: Bool = false
    
    // MARK: - FILTERS
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
    
    // Converting all fetched credentials to Filter objects
    var convertedCredentialFilters: [Filter] {
        allCredentials.map { credential in
            Filter(name: credential.credentialName, icon: "person.text.rectangle.fill", credential: credential)
        }
    }
    
    
    // MARK: - Core Data fetch requests
    // All tags sorted by name
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tagName)]) var tags: FetchedResults<Tag>
    
    // Retrieving all saved renewal periods
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodName)]) var renewals: FetchedResults<RenewalPeriod>
    
    // Fetching all saved credentials
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var allCredentials: FetchedResults<Credential>
    
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
                
                // MARK: - TAGS
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
                
                // MARK: - Credentials Grouping
                
                // IF NO credentials have yet been entered (or have been deleted)
                if allCredentials.isEmpty {
                    Section("Add License, Certification, or Other Credential") {
                        NoCredentialsView()
                    }//: SECTION
                }//:
                
                // MARK: Credential Parent Group
                // For whenever at least one credential has been saved
                ForEach(allCredentials) { credential in
                    // Creating a section for each renewal period for the credential
                    Section {
                        ForEach(convertedRenewalFilters.filter{$0.credential == credential}) { filter in
                            NavigationLink(value: filter) {
                                Label(filter.name, systemImage: "calendar.badge.clock")
                                    .badge(
                                        filter.renewalPeriod?.renewalCurrentActivities.count ?? 0
                                    )
                                    .contextMenu {
                                        // Edit Renewal Period
                                        Button {
                                            editRenewalPeriod(filter)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        // Delete Renewal Period
                                        Button(role: .destructive) {
                                            renewalToDelete = filter.renewalPeriod
                                            showDeletingRenewalAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }
                                    
                            }//: NAV LINK
                        }//: LOOP
                    } header: {
                        HStack {
                            Text("\(credential.credentialName) Renewals")
                            Spacer()
                            
                            Button {
                                showRenewalPeriodView = true
                            }label: {
                                Label("Add Renewal Period", systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            }
                            
                        }//: HSTACK
                    }//: SECTION w/ custom header
                }//: LOOP (allCredentials ForEach)
                
                
                
            } //: LIST
            // Adding this code to prevent a stale state between times
            // when the user decides to edit a renewal period
            .onChange(of: showRenewalPeriodView) {isPresented in
                if !isPresented {
                    renewalToEdit = nil
                }
            }//:  ON CHANGE
            
            // MARK: - Toolbar
            .toolbar {
                // Awards sheet toggle button
                Button {
                    showAwardsSheet.toggle()
                } label: {
                    Label("Show awards", systemImage: "rosette")
                }//: BUTTON
                
#if DEBUG
                Button {
                    dataController.deleteAll()
                    dataController.createSampleData()
                } label: {
                    Label("Add Samples", systemImage: "flame")
                }
#endif
                
            } //: TOOLBAR
            // MARK: - Alerts
            // RENAMING TAG ALERT
            .alert("Rename Tag", isPresented: $showRenamingAlert) {
                Button("OK", action: confirmTagRename)
                Button("Cancel", role: .cancel) {}
                TextField("New tag name:", text: $newTagName)
            } //: ALERT
            // DELETING RENEWAL PERIOD ALERT
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
            // MARK: - SHEETS
            .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
            .sheet(isPresented: $showRenewalPeriodView){
                if let renewal = renewalToEdit {
                    RenewalPeriodView(renewalPeriod: renewal)
                    .presentationDetents([.medium])
                } else {
                    RenewalPeriodView(renewalPeriod: nil)
                        .presentationDetents([.medium])
                }
                
            }//: SHEET
            .onAppear {
                renewalToEdit = nil
                renewalToDelete = nil
            }
        
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

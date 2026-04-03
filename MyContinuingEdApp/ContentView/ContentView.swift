//
//  ContentView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController
    @Environment(\.certificateBrain) var certificateBrain

    @Environment(\.spotlightCentral) var spotlightCentral
    @Environment(\.requestReview) var requestReview
    @StateObject private var viewModel: ViewModel
    
    @State private var showUpgradetoPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus? = nil
    
    // Deletion properties
    @State private var showDeletionErrorAlert: Bool = false
    @State private var deletionErrorMessage: String = ""
    
    // MARK: - BODY
    var body: some View {
        if viewModel.allActivities.isEmpty && viewModel.allCredentials.isEmpty {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    NoItemView(
                        noItemTitleText: "First Things First",
                        noItemMessage: "Before adding CE activities, go to the sidebar (CE Filters) and add a credential along with a renewal period to get started.",
                        noItemImage: "1.circle.fill"
                    )
                    .padding(.horizontal, 20)
                    Spacer()
                }//: VSTACK
                .frame(width: geo.size.width, height: geo.size.height)
                .ignoresSafeArea()
                .navigationTitle("CE Activities")
            }//: GEO READER
        } else {
            /// The List section displays the ActivityROW and not the ActivityView. The
            /// ActivityView struct is for showing the details of each activity.
            List(selection: $viewModel.dataController.selectedActivity) {
                // MARK: Regular list with no header section
                if dataController.sortType != .name {
                    ForEach(viewModel.computedCEActivityList) { activity in
                        ActivityRow(activity: activity)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.delete(activity: activity)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }//: BUTTON
                            }//: SWIPE
                    }//: LOOP
                } else {
                    // MARK: List With Activity Name Alphabetical Sorting
                    ForEach(viewModel.sortedKeys, id: \.self) { key in
                        Section(header: Text(key)) {
                            
                            // Ce Activity row under the key header
                            ForEach(viewModel.dataController.activitiesBeginningWith(letter: key)) { activity in
                                ActivityRow(activity: activity)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            viewModel.delete(activity: activity)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }//: BUTTON
                                    }//: SWIPE
                            } //: LOOP
                        }//: SECTION
                    }//: LOOP
                }//: IF - ELSE
            } //: LIST
            .navigationTitle("CE Activities")
            .searchable(
                text: $viewModel.dataController.filterText,
                tokens: $viewModel.dataController.filterTokens,
                suggestedTokens: .constant(viewModel.dataController.suggestedFilterTokens),
                prompt: "Filter CE activities, or type # to add tags") { tag in
                    Text(tag.tagTagName)
                }
            // MARK: - ALERTS
                .alert("CE Activity Deletion Warning", isPresented: $viewModel.showDeleteWarning) {
                    Button("Delete", role: .destructive) {
                        if let selectedActivity = viewModel.activityToDelete {
                            fullyDeleteCeActivity(selectedActivity)
                        }//: IF LET
                    } //: DELETE button
                    Button("Cancel", role: .cancel) {viewModel.activityToDelete = nil}
                } message: {
                    if let activity = viewModel.activityToDelete {
                        Text("Warning! You are about to delete the activity '\(activity.ceTitle)'.  This will delete its certificate along with any reflections.  This action cannot be undone.")
                    }//: IF LET
                }//: ALERT (delete)
            
                .alert("CE Deletion Error", isPresented: $showDeletionErrorAlert) {
                    Button("OK"){}
                } message: {
                    Text(deletionErrorMessage)
                }//: ALERT (deletion error)
            
            // MARK: - ON CHANGE
                .onChange(of: deletionErrorMessage) {_ in
                    let trimmedMessage = deletionErrorMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedMessage.isNotEmpty {
                        showDeletionErrorAlert = true
                    }//: IF
                }//: ON CHANGE
            
            // MARK: - TOOLBAR
                .toolbar {
                    ContentViewToolbarView() {
                        if #available(iOS 17, *) {
                            // Use the dataController's createActivity method and item
                            // will be automatically added to Spotlight's index
                            do {
                                try dataController.createActivity()
                            } catch  {
                                showUpgradetoPaidSheet = true
                            }
                            
                        } else {
                            // Manually add CeActivity to Spotlight's index
                            do {
                                let newCe = try dataController.createNewCeActivityIOs16()
                                spotlightCentral?.addCeActivityToDefaultIndex(newCe)
                            } catch  {
                                showUpgradetoPaidSheet = true
                            }
                        }
                    }//: CLOSURE
                } //: TOOLBAR
                  // MARK: - SHEETS
                .sheet(isPresented: $showUpgradetoPaidSheet) {
                    UpgradeToPaidSheet(itemMaxReached: "CE activities")
                }//: SHEET
            
            // MARK: - ON APPEAR
                .onAppear {
                    askForReview()
                    #if DEBUG
                    print("The # of credentials present: \(viewModel.allCredentials.count)")
                    #endif
                }//: ON APPEAR
        }//: IF - ELSE
        
    } //: BODY
    // MARK: - METHODS
    func askForReview() {
        if viewModel.shouldRequestReview {
            requestReview()
        }
    }//: askForReview
    
    /// ContentView method that deletes a selected CeActivity CoreData object along with all media files associated with it.
    /// - Parameter activity: CeActivity that is to be deleted
    ///
    /// The method first checks if the activity has a CE certificate and/or any audio reflections associated with it, and then
    /// deletes them first.  Once those are successfully deleted, then the core data object is removed.  However, since the
    /// media-related deletion methods can throw errors, this method will update the deletionErrorMessage and return without
    /// removing the CoreData object instead.  Once the deletionErrorMessage updates, then a new alert will be generated for
    /// the user.
    func fullyDeleteCeActivity(_ activity: CeActivity) {
        if let certBrain = certificateBrain, activity.hasCompletionCertificate {
            Task { @MainActor in
                // TODO: Add code
//                guard confirmedCert else {
//                    NSLog(">>> Invalid hasCompletionCertificate value for \(activity.ceTitle).")
//                    NSLog(">>> Unable to find a certificate or coordinator object for the activity when there should be one.")
//                    deletionErrorMessage = "The app's internal information on this activity shows that there should be a certificate saved, but none was found (or could be found). Reach out to the developer for assistance."
//                    return
//                }//: GUARD
                
                do {
                    // TODO: Add code
                } catch {
                    NSLog(">>> Error deleting the CE activity \(activity.ceTitle) due to an error when trying to delete the associated certificate file.")
                    NSLog(">>> Neither the activity nor certificate were deleted.")
                    NSLog(">>> Likely cause is an invalid URL in the certificate coordinator for the associated certificate due to the actual file being moved or deleted without updating the coordinator list accordingly.")
                    deletionErrorMessage = "Unable to delete the certificate because an error was encountered while trying to delete the certificate associated with it. Try manually deleting the certificate first and then try again."
                    return
                }//: DO - CATCH
                
                viewModel.deleteCeActivityCoreDataObject(activity)
                return
            }//: TASK
        } else if activity.hasCompletionCertificate {
            NSLog(">>>Error deleting the CE activity \(activity.ceTitle) due to a nil certificateBrain value. However, the hasCompletionCertificate property is still true.")
            deletionErrorMessage = "Unable to delete the certificate because an error was encountered while trying to delete the certificate associated with it. Try manually deleting the certificate first and then try again."
            return
        }//: IF - ELSE IF
        
        viewModel.deleteCeActivityCoreDataObject(activity)
        viewModel.activityToDelete = nil
    }//: fullyDeleteCeActivity
    
    
    
    // MARK: - INIT
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
    
    
}//: STRUCT


// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dataController: .preview)
    }
}

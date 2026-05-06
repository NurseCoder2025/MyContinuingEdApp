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

    @Environment(\.spotlightCentral) var spotlightCentral
    @Environment(\.requestReview) var requestReview
    @StateObject private var viewModel: ViewModel
    
    @State private var showUpgradetoPaidSheet: Bool = false
    @State private var selectedUpgradeOption: PurchaseStatus? = nil
    
    // Deletion properties
    @State private var showDeletionErrorAlert: Bool = false
    @State private var deletionErrorMessage: String = ""
    
    // Warning box-related
    @State private var showRenewalAcknowledgementConfirmation: Bool = false
    private let syncBrain = SmartSyncBrain.shared
    // MARK: - COMPUTED PROPERTIES
    
    var addRenewalWarningBoxMessage: String {
        if userPaidSupportLevel == .basicUnlock {
            return "In order to sync CE certificates across your devices in iCloud, you need to have information pertaining to the current renewal period in the app. Otherwise, certificates will only be stored locally on the device."
        } else {
            return "Please add at least one renewal period to this app to help keep your CE activities organized."
        }//: IF ELSE (userPaidSupportLevel == .basicUnlock)
    }//: addRenewalWarningBoxMessage
    
    var renewalEndingBoxMessage: String {
        if let renewal = syncBrain.renewalForWarning {
            if renewal.isRenewalPrevious() {
                return "The renewal period under which CE certificates were being uploaded to iCloud with SmartSync has now ended. In order to continue using SmartSync as a CE Cache Core user, please acknowledge an important reminder concerning SmartSync by tapping on the acknowledge button."
            } else {
                return "The current renewal period is about to end. Please tap on the 'Acknowledge' button to review important information regarding certificates currently stored in iCloud prior to the renewal's ending. SmartSync will stop functioning after the renewal ends if this information is not acknowledged by you."
            }//: IF LET (renewal = syncBrain.renewalForWarning)
        } else {
            return "The current renewal period is about to end. Please tap on the 'Acknowledge' button to review important information regarding certificates currently stored in iCloud prior to the renewal's ending. SmartSync will stop functioning after the renewal ends if this information is not acknowledged by you."
        }//: IF LET (renewal)
    }//: renewalEndingBoxMessage
    
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
            VStack {
                if viewModel.shouldDisplayWarningBoxSection() {
                    ScrollView {
                        VStack(spacing: 8){
                            // Display any pertinent warning boxes to the user
                            if viewModel.showNoCredentialsWarningBox {
                                UserWarningBoxView(
                                    warningTitle: "Add Credential",
                                    warningText: "To make the most of this app (and to sync certificates in iCloud if you are a CE Cache Core user), please add the license or other credential that you're tracking continuing education activities for.",
                                    warningAccentColor: Color.gray
                                )//: USERWARNINGBOXVIEW
                            }//: IF (showNoCredentialsWarningBox)
                            
                            if viewModel.showAddRenewalBox {
                                UserWarningBoxView(
                                    warningTitle: "Add Renewal Period",
                                    warningText: addRenewalWarningBoxMessage,
                                    warningAccentColor: Color.indigo
                                )//: USER WARNING BOX VIEW
                            }//: IF (showAddRenewalBox)
                            
                            if viewModel.showUpcomingRenewalEndingBox {
                                UserWarningBoxView(
                                    warningTitle: "Renewal Ending Soon",
                                    warningText: renewalEndingBoxMessage,
                                        showActionButton: true,
                                        buttonLabelText: "Acknowledge"
                                ) {
                                    showRenewalAcknowledgementConfirmation = true
                                }
                            }//: IF (showUpcomingRenewalEndingBox)
                        }//: VSTACK
                    }//: SCROLLVIEW
                    .frame(maxHeight: 250)
                }//: IF (shouldDisplayWarningBoxSection)
                
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
            }//: VSTACK
            .navigationTitle("CE Activities")
            .searchable(
                text: $viewModel.dataController.filterText,
                tokens: $viewModel.dataController.filterTokens,
                suggestedTokens: .constant(viewModel.dataController.suggestedFilterTokens),
                prompt: "Filter CE activities, or type # to add tags") { tag in
                    Text(tag.tagTagName)
                }
            // MARK: - ALERTS
                .alert("CE Deletion Error", isPresented: $showDeletionErrorAlert) {
                    Button("OK"){}
                } message: {
                    Text(deletionErrorMessage)
                }//: ALERT (deletion error)
            
            // MARK: - CONFIRMATION DIALOGS
                .confirmationDialog("CE Activity Deletion Warning", isPresented: $viewModel.showDeleteWarning) {
                    Button("Delete", role: .destructive) {
                        if let selectedActivity = viewModel.activityToDelete {
                           // TODO: Add code
                        }//: IF LET
                    } //: DELETE button
                    Button("Cancel", role: .cancel) {viewModel.activityToDelete = nil}
                } message: {
                    if let activity = viewModel.activityToDelete {
                        Text("Warning! You are about to delete the activity '\(activity.ceTitle)'.  This will delete its certificate along with any reflections.  This action cannot be undone.")
                    }//: IF LET
                }//: ALERT (delete)
            
                .confirmationDialog("Acknowledge Renewal Transition", isPresented: $showRenewalAcknowledgementConfirmation) {
                    Button("Acknowledge") {
                        if let renewal = syncBrain.renewalForWarning {
                            viewModel.userAcknowledgesRenewalWarning(for: renewal)
                        }//: IF LET (renewal)
                    }//: BUTTON (acknowledge)
                    Button("Cancel", role: .cancel) {} //: BUTTON (cancel)
                } message : {
                    Text(syncBrain.renewalWindowWarningBoxMessage)
                }//: CONFIRMATION DIALOG
            
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

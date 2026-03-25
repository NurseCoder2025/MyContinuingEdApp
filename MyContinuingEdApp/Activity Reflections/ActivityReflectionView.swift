//
//  ActivityReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

// Note: This view is a complete screen (not a sheet) due to a
// NavigationLink on ActivityCompletionView

import SwiftUI

struct ActivityReflectionView: View {
    // MARK: - PROPERTIES
    @Environment(\.audioBrain) var audioBrain
    @StateObject var viewModel: ViewModel
    
    let dataController: DataController
    @ObservedObject var reflection: ActivityReflection
    
    @State private var showPromptSelectionSheet: Bool = false
    @State private var showResponseDeletionWarning: Bool = false

    // MARK: - BODY
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Reflections on \(viewModel.assignedActivityTitle)")
                        .font(.largeTitle)
                    Text("To complete this reflection, please select and respond to one prompt.")
                }//: HEADER SECTION
                
                Section("Learning Prompts") {
                    // Prompt Selection
                    Menu {
                        Button {
                            viewModel.createRandomPrompt()
                        } label: {
                            Text("Random Prompt")
                        }//: BUTTON
                        
                        Button {
                            showPromptSelectionSheet = true
                        } label: {
                            Text("Let Me Choose")
                        }//: BUTTON
                    } label: {
                        Text(viewModel.responsesCount > 0 ? "Select Another Prompt" : "Select Prompt")
                    }//: MENU
                    
                    // View existing selected prompts for viewing/editing
                    if let aBrain = audioBrain {
                        List {
                            ForEach(viewModel.currentResponses) { response in
                                NavigationLink {
                                    PromptResponseView(response: response, data: dataController, audioBrain: aBrain)
                                } label: {
                                    ActivityReflectionPromptResponseRowView(response: response)
                                }//: NAV LINK
                                .swipeActions(edge: .trailing) {
                                    // MARK: Delete Button
                                    Button(role: .destructive) {
                                        viewModel.responseToDelete = response
                                        showResponseDeletionWarning = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                            .labelStyle(.iconOnly)
                                    }//: BUTTON
                                }//: SWIPE
                            }//: LOOP
                        }//: LIST
                    }//: IF LET (audioBrain)
                    
                }//: SECTION
                
                DisclosureGroup("New & Surprising Info") {
                    Toggle("Were you surprised by anything you learned?", isOn: $reflection.wasSurprised)
                    
                    if reflection.wasSurprised {
                        TextField(
                            "Anything surprising",
                            text: $reflection.reflectionSurprises,
                            prompt: Text("Did you learn anything that surprised you during the activity?"),
                            axis: .vertical
                        )
                        .font(.title3)
                    } //: IF - was surprised
                }//: DISCLOSURE GROUP - Surprising learning
                
                DisclosureGroup("Other Reflections") {
                    TextField(
                        "Other thoughts",
                        text: $reflection.afGeneralReflection,
                        prompt: Text("Do you have any other reflections or thoughts regarding this activity?"),
                        axis: .vertical
                    )
                    .font(.title3)
                }//: DISCLOSURE GROUP - General thoughts
                
            }//: FORM
        }//: NAV STACK
        // MARK: - SHEETS
        .sheet(isPresented: $showPromptSelectionSheet) {
            let newResponse = viewModel.createInitialResponseWithoutPrompt()
            PromptSelectionSheet(response: newResponse)
        }//: SHEET
        
        // MARK: - ALERTS
        .alert("Delete Response?", isPresented: $showResponseDeletionWarning) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedResponse()
            }//: BUTTON
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting this response will permanently remove whatever you typed in for an answer along with any recorded audio (if applicable). Are you sure you want to delete this response?")
        }//: ALERT
        
        .alert(viewModel.fileErrorTitle, isPresented: $viewModel.showFileErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.fileErrorMessage)
        }//: AlERT
        
         // MARK: - AUTO SAVING FUNCTIONS
        .onReceive(reflection.objectWillChange) { _ in
            dataController.queueSave()
        }//: ON RECEIVE
        
        // MARK: - ON DISAPPEAR
        .onDisappear {
            dataController.save()
        }//: ON DISAPPEAR
        
    } //: BODY

    // MARK: - INIT
    init(dataController: DataController, reflection: ActivityReflection) {
        self.dataController = dataController
        self.reflection = reflection
        
        let newViewModel = ViewModel(dataController: dataController, reflection: reflection)
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
struct ActivityReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReflectionView(dataController: .preview, reflection: .example)
            
    }
}

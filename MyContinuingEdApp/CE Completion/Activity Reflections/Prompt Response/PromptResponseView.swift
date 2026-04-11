//
//  PromptTextResponseEntryView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/29/26.
//

import SwiftUI

struct PromptResponseView: View {
    // MARK: - PROPERTIES
    @ObservedObject var response: ReflectionResponse
    
    @StateObject var audioHolder: AudioDataHolder = AudioDataHolder()
    
    @State private var entryTypeSelection: ResponseEntryType = .writtenResponse
    @State private var showPromptSelectionSheet: Bool = false
    
    let dataController: DataController
    // MARK: - COMPUTED PROPERTIES
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // Header
            PromptHeaderView(response: response) {
                showPromptSelectionSheet = true
            }//: PromptHeaderView (onChangePrompt closure)
            
            // Answer type selection picker
            Picker("Select Response Type", selection: $entryTypeSelection) {
                ForEach(ResponseEntryType.allCases) { type in
                    Text(type.id).tag(type)
                }//: LOOP
            }//: PICKER
            .pickerStyle(.segmented)
            
            // Response View
            switch entryTypeSelection {
            case .writtenResponse:
                PromptResponseTextEntryView(
                    response: response,
                    dataController: dataController
                )
            case .audioResponse:
                // TODO: Replace with updated subview
                Text("Audio Response View")
            }//: SWITCH
            
        }//: VSTACK
        .environmentObject(audioHolder)
        // MARK: - ON CHANGE
        .sheet(isPresented: $showPromptSelectionSheet) {
                PromptSelectionSheet(response: response)
        }//: SHEET
        // MARK: - ON DISAPPEAR
        .onDisappear {
            response.markResponseAsComplete()
            dataController.save()
        }//: onDisappear
    }//: BODY
    // MARK: - INIT
    
    init(
        response: ReflectionResponse,
        data: DataController
    ) {
        self.response = response
        self.dataController = data
        
    }//: INIT
    
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    PromptResponseView(response: .example, data: .preview)
}//: PREVIEW

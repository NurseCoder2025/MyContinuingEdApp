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
    let audioBrain: AudioReflectionBrain
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
                    audioBrain: audioBrain,
                    dataController: dataController
                )
            case .audioResponse:
                AudioReflectionRecordAndPlayView(audioBrain: audioBrain, response: response)
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
        data: DataController,
        audioBrain: AudioReflectionBrain
    ) {
        self.response = response
        self.dataController = data
        self.audioBrain = audioBrain
        
    }//: INIT
    
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    PromptResponseView(response: .example, data: .preview, audioBrain: .preview)
}//: PREVIEW

//
//  AudioReflectionRecorderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/19/26.
//

import SwiftUI

struct AudioReflectionRecordAndPlayView: View {
    // MARK: - PROPERTIES
    var dataController: DataController
    var audioBrain: AudioReflectionBrain
    
    @ObservedObject var prompt: ReflectionPrompt?
    @ObservedObject var response: ReflectionResponse
    
    @StateObject private var viewModel: ViewModel
    
    @State var audioToTranscribe: Data?
    
    // MARK: - BODY
    var body: some View {
        // If the ReflectionResposne has audio already recorded, show the player
        
        // Show the Transcribing status once audio has been recorded
        
    }//: BODY
    
    // MARK: - INIT
    
    init(
        dataController: DataController,
        audioBrain: AudioReflectionBrain,
        response: ReflectionResponse
    ) {
        self.dataController = dataController
        self.audioBrain = audioBrain
        self.response = response
        
        if let selectedPrompt = response.question {
            self.prompt = selectedPrompt
        }
        
        let newViewModel = ViewModel(aBrain: audioBrain, dataController: dataController)
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    AudioReflectionRecordAndPlayView(
        dataController: .preview,
        audioBrain: .preview,
        prompt: .shortExample,
        response: .example
    )
}//: PREVIEW

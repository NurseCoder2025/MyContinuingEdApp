//
//  PromptResponseTextEntryView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import SwiftUI

struct PromptResponseTextEntryView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var audioData: AudioDataHolder
    @ObservedObject var response: ReflectionResponse
    
    @StateObject var viewModel: ViewModel
    
    @State private var okToTranscribeAudio: Bool = false
    
    let audioBrain: AudioReflectionBrain
    let dataController: DataController
    
    // MARK: - BODY
    var body: some View {
       
        
        
        
    }//: BODY
    
    // MARK: - INIT
    
    init(response: ReflectionResponse, audioBrain: AudioReflectionBrain, dataController: DataController) {
        self.response = response
        self.audioBrain = audioBrain
        self.dataController = dataController
        
        let newViewModel = ViewModel(aBrain: audioBrain, dataController: dataController)
        _viewModel = StateObject(wrappedValue: newViewModel)
        
        okToTranscribeAudio = dataController.allowsAutoTranscriptionOfAudio
        
    }//: INIT
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptResponseTextEntryView(response: .example, audioBrain: .preview, dataController: .preview)
}//: PREVIEw

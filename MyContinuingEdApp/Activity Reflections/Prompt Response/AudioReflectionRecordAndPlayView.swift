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
    
    private var prompt: ReflectionPrompt?
    @ObservedObject var response: ReflectionResponse
    
    @StateObject private var viewModel: ViewModel
    
    
    
    // MARK: - BODY
    var body: some View {
        
        
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
        }//: IF LET
        
        let newViewModel = ViewModel(aBrain: audioBrain, dataController: dataController)
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    AudioReflectionRecordAndPlayView(
        dataController: .preview,
        audioBrain: .preview,
        response: .example
    )
}//: PREVIEW

//
//  AudioReflectionRecorderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/19/26.
//

import SwiftUI

struct AudioReflectionRecordAndPlayView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    let audioBrain: AudioReflectionBrain
    
    @ObservedObject var response: ReflectionResponse
    
    // MARK: - BODY
    var body: some View {
        if response.hasAudioReflection {
            AudioPlayerControlView(audioBrain: audioBrain, response: response)
        } else {
            AudioRecordingControlView(response: response)
        }//: IF ELSE (hasAudioReflection)
    }//: BODY
    
    // MARK: - INIT
    
    init(
        audioBrain: AudioReflectionBrain,
        response: ReflectionResponse
    ) {
        self.audioBrain = audioBrain
        self.response = response
        
        
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    AudioReflectionRecordAndPlayView(
        audioBrain: .preview,
        response: .example
    )
}//: PREVIEW

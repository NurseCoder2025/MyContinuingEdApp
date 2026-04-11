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
    
    @ObservedObject var response: ReflectionResponse
    
    // MARK: - BODY
    var body: some View {
        if response.hasAudioReflection {
            AudioPlayerControlView(response: response)
        } else {
            AudioRecordingControlView(response: response)
        }//: IF ELSE (hasAudioReflection)
    }//: BODY
    
    // MARK: - INIT
    
    init(
        response: ReflectionResponse
    ) {
        self.response = response
        
        
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    AudioReflectionRecordAndPlayView(
        response: .example
    )
}//: PREVIEW

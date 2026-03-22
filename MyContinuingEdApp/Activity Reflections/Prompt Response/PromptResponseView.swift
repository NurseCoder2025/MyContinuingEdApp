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
    
    var dataController: DataController
    var audioBrain: AudioReflectionBrain
    // MARK: - COMPUTED PROPERTIES
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // Answer type selection picker
            Picker("Select Response Type", selection: $entryTypeSelection) {
                ForEach(ResponseEntryType.allCases) { type in
                    Text(type.id).tag(type)
                }//: LOOP
            }//: PICKER
            .pickerStyle(.segmented)
            
            
            
        }//: VSTACK
        .environmentObject(audioHolder)
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

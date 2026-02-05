//
//  PromptTextResponseEntryView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/29/26.
//

import SwiftUI

struct PromptResponseEntryView: View {
    // MARK: - PROPERTIES
    @ObservedObject var response: ReflectionResponse
    
    @State private var entryTypeSelection: ResponseEntryType = .writtenResponse
    
    // MARK: - COMPUTED PROPERTIES
    
    // MARK: - BODY
    var body: some View {
        // Answer type selection picker
        Picker("Select Response Type", selection: $entryTypeSelection) {
            ForEach(ResponseEntryType.allCases) { type in
                Text(type.id).tag(type)
            }//: LOOP
        }//: PICKER
        .pickerStyle(.segmented)
        
        
        

    }//: BODY
}//: STRUCt


// MARK: - PREVIEW
#Preview {
    PromptResponseEntryView(response: .example)
}

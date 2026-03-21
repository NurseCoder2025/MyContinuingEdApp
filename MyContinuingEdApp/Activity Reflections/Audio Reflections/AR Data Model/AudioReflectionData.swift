//
//  AudioReflectionData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import Foundation

/// Data model for holding binary data representing audio recorded by the user (Pro-subscribers)
/// that was used for reflecting on what was learned during a continuing education activity.
struct AudioReflectionData: Codable {
    // MARK: - PROPERTIES
    let audioReflectionData: Data?
    
    // MARK: - INIT
    init(containing audioData: Data? = nil) {
        self.audioReflectionData = audioData
    }//: INIT
    
}//: AudioReflectionData

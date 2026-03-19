//
//  AudioReflectionViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/18/26.
//

import Foundation
import SwiftUI

extension ActivityAudioReflectionView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        @Published var isRecording: Bool = false
        @Published var isPlaying: Bool = false
        @Published var isTranscribing: Bool = false
        
        // Error alerts for user
        @Published var showAlertMessage: Bool = false
        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""
        
        var audioBrain: AudioReflectionBrain
        
        // MARK: - METHODS
        
        
        
        
        
        
        // MARK: - INIT
        
        init(brain: AudioReflectionBrain) {
            self.audioBrain = brain
        }//: INIT
        
    }//: CLASS
    
    
}//: EXTENSION

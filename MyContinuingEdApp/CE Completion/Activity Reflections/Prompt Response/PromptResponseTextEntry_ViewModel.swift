//
//  PromptResponse_ViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import AVFoundation
import Foundation
import Speech
import SwiftUI

extension PromptResponseTextEntryView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        
        @Published var transcribingStatus: TranscribingStatus = .waiting
        
        let tempTranscriptionURL = URL.temporaryDirectory.appending(path: "audioForTranscription\(String.audioFormatExtension)", directoryHint: .notDirectory)
        
        let fileSystem = FileManager()
        
        // Transcription Errors
        @Published var showTranscriptionErrorAlert: Bool = false
        var transcriptionErrorMessage: String = ""
        var transcriptionErrorTitle: String = "Transcription Error"
        
        // Other needed classes
        var dataController: DataController
        
        // MARK: - COMPUTED PROPERTIES
        
        var isProSubscriber: Bool {
            dataController.purchaseStatus == PurchaseStatus.proSubscription.id
        }//: isProSubscriber
        
        var showTextEntryFields: Bool {
            transcribingStatus != .transcribing && transcribingStatus != .completed
        }//: showTextEntryFiels
        
        // MARK: - TRANSCRIBING METHODS
        
        func requestTranscribingPermission(data: Data, for response: ReflectionResponse) {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                Task {@MainActor in
                    switch authStatus {
                    case .notDetermined:
                        self.transcriptionErrorMessage = "Unable to transcribe audio due to an unknown authorization status for the Speech Recognition feature on your device. Please add this app to the list of approved apps in your device's Privacy & Security settings."
                        self.showTranscriptionErrorAlert = true
                    case .denied:
                        self.transcriptionErrorMessage = "Unable to transcribe audio until you grant the app permission to use the device's Speech Recognition feature. You can change this in your device's Privacy & Security settings."
                        self.showTranscriptionErrorAlert = true
                    case .restricted:
                        self.transcriptionErrorMessage = "This app needs full permission to use the Speech Recognition feature on your device in order to transcribe your audio reflections. However, currently access is restricted. Please change this in your device's Privacy & Security settings."
                        self.showTranscriptionErrorAlert = true
                    case .authorized:
                        Task.detached {
                            // TODO: add replacement code here
                        }//: TASK
                    @unknown default:
                        self.transcriptionErrorMessage = "Unable to transcribe audio due to an unknown authorization status for the Speech Recognition feature on your device. Please add this app to the list of approved apps in your device's Privacy & Security settings."
                        self.showTranscriptionErrorAlert = true
                    }//: SWITCH
                }//: TASK
            }//: requestAuthorization (closure)
        }//: requestTranscribingPermission()
        
      
        
        
        // MARK: - INIT
        
        init(dataController: DataController) {
            self.dataController = dataController
            
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: EXTENSION

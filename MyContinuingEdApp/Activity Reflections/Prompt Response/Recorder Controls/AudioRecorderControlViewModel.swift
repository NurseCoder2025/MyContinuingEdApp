//
//  AudioRecorderControlViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import AVFoundation
import Foundation
import SwiftUI

extension AudioRecordingControlView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        @ObservedObject var response: ReflectionResponse
        
        @Published var recordingStatus: RecordingStatus = .waiting
        @Published var audioBars: [AudioMetricBar] = []
        
        // Recorder properties
        private var recordingSession = AVAudioSession.sharedInstance()
        private var audioRecorder: AVAudioRecorder?
        let tempRecordingURL = URL.temporaryDirectory.appending(
            path: "recording\(String.audioFormatExtension)",
            directoryHint: .notDirectory
        )//: appending
        
        // Recording Errors
        @Published var showRecordingErrorAlert: Bool = false
        var recordingErrorMessage: String = ""
        var recordingErrorTitle: String = "Recording Error"
        
        // MARK: - COMPUTED PROPERTIES
        
        var elapsedRecordingTime: TimeInterval {
            if let recorder = audioRecorder {
                return recorder.currentTime
            } else {
                return .zero
            }//: IF LET ELSE
        }//: elapsedRecordingTime
        
        // MARK: - METHODS
        
        func requestRecordingPermission() {
            // Using different methods based on iOS version due to Apple deprecating the requestRecordPermission
            // method after iOS 16 (and equivalent).
            if #available(iOS 17.0, *) {
                let recordingSystem = AVAudioApplication.shared
                switch recordingSystem.recordPermission {
                case .undetermined:
                    recordingErrorMessage = "Unable to record audio due to permission uncertainty. Please check your device's Privacy settings and enable microphone access for this app."
                    showRecordingErrorAlert = true
                case .denied:
                    recordingErrorMessage = "Unable to record audio because permission has been denied. Please grant the app permission to the microphone in your device's Privacy settings in order to use the audio reflection feature."
                    showRecordingErrorAlert = true
                case .granted:
                    startRecording()
                @unknown default:
                    recordingErrorMessage = "Unable to record audio due to an unknown permission status. Please check your device's Privacy settings and enable microphone access for this app."
                    showRecordingErrorAlert = true
                }//: SWITCH
            } else if #available(iOS 16.0, *) {
                recordingSession.requestRecordPermission { granted in
                    Task{@MainActor in
                        if granted {
                            self.startRecording()
                        } else {
                            self.recordingErrorMessage = "Unable to record audio because permission has been denied. Please grant the app permission to the microphone in your device's Privacy settings in order to use the audio reflection feature."
                            self.showRecordingErrorAlert = true
                        }//: IF (granted)
                    }//: requestRecordPermission
                }//: TASK
            }//: IF ELSE (#available)
        }//: requestRecordingPermission()
        
        private func startRecording() {
            setupAudioObservers()
            let settings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1
            ]
            
            do {
                try recordingSession.setCategory(.playAndRecord)
                try recordingSession.setActive(true)
                
                audioRecorder = try AVAudioRecorder(url: tempRecordingURL, settings: settings)
                audioRecorder?.isMeteringEnabled = true
                recordingStatus = .recording
                audioRecorder?.record()
            } catch {
                NSLog(">>> Error recording audio: \(error.localizedDescription)")
                recordingErrorMessage = "Failed to configure the recording for your audio reflection: \(error.localizedDescription)"
                recordingStatus = .error
            }//: DO - CATCH
        }//: startRecording()
        
        func pauseRecording() {
            if let recorder = audioRecorder {
                recorder.pause()
                recordingStatus = .paused
            }//: IF LET
        }//: pauseRecording()
        
        func resumeRecording() {
            if let recorder = audioRecorder {
                if recorder.record() {
                    recordingStatus = .recording
                }//: IF (record())
            }//: IF LET (recorder)
        }//: resumeRecording()
        
        func stopRecording() {
            audioRecorder?.stop()
            recordingStatus = .stopped
            
            do {
                let tempPlayer = try AVAudioPlayer(contentsOf: tempRecordingURL)
                response.audioLength = tempPlayer.duration
                response.hasAudioReflection = true
            } catch {
                NSLog(">>> Error creating a temporary audio player to get the length of a completed recording session. Error: \(error.localizedDescription)")
                NSLog(">>> Audio data properties for the associated reflection response object are left at their default values. Response for prompt: \(response.getAssignedPrompt())")
                recordingErrorMessage = "Problem getting recording data from the audio file. Please try recording again."
                showRecordingErrorAlert = true
            }//: DO-CATCH
        }//: stopRecording()
        
        func changeRecordingAction() {
            switch recordingStatus {
            case .waiting:
                requestRecordingPermission()
            case .recording:
                pauseRecording()
            case .paused:
                resumeRecording()
            case .stopped:
                return
            case .error:
                return
            }//: SWITCH
        }//: changeRecordingAction()
        
        func createNewAudioMetricBar() {
            guard recordingStatus == .recording else { return }
            
            Task{@MainActor in
                if let player = audioRecorder {
                    player.updateMeters()
                    let currentPower = player.peakPower(forChannel: 0)
                    let newBar = AudioMetricBar(power: currentPower)
                    audioBars.append(newBar)
                }//: IF LET
            }//: TASK
        }//: createNewAudioMetricBar()
        
        // MARK: - AUDIO OBSERVERS
        
        /// AudioReflectionRecorderViewModel method intended to create observers that handle system events that can interrupt an audio recording
        /// session, such as a phone call.
        ///
        /// This method always removes any existing interruption observers before creating a new one.
        private func setupAudioObservers() {
            let noticeCenter = NotificationCenter.default
            let interruptNotification = AVAudioSession.interruptionNotification
            
            noticeCenter.removeObserver(self, name: interruptNotification, object: recordingSession)
            
            noticeCenter.addObserver(
                self,
                selector: #selector(handleAudioInterruptions(_:)),
                name: interruptNotification,
                object: recordingSession
            )//: OBSERVER
        }//: setupAudioObservers()
        
        /// Selector method in AudioReflectionRecorderViewModel for handling situations when an active recording session is
        /// interrupted by a device event, such as a phone call or similar event.
        /// - Parameter notification: Notification with the name "interruptNotification" (as part of AVAudioSession)
        ///
        /// This method will only pause the recording automatically.  Recording must be resumed manually by the user after the interruption
        /// ends.  This helps for a better user experience as it is best that the user decides when to resume recording after an interruption.
        @objc private func handleAudioInterruptions(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                    let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                    let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return } //: GUARD
            
            switch type {
            case .began:
                pauseRecording()
            case .ended:
                return
            @unknown default:
                NSLog(">>> A new interruption type was added to the AVAudioSession.InterruptionType enum. Please update the switch statement in AudioReflectionBrain.swift")
                pauseRecording()
            }//: SWITCH
            
        }//: handleAudioInterruptions()
        
        // MARK: - INIT
        init(response: ReflectionResponse) {
            self.response = response
        }//: INIT
        
        // MARK: - DEINIT
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }//: DEINIT
        
    }//: CLASS
    
}//: EXTENSION

//
//  AudioReflectionRecorderViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/19/26.
//

import AVFoundation
import Foundation
import Speech
import SwiftUI

extension AudioReflectionRecordAndPlayView {
    
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
        var audioBrain: AudioReflectionBrain
        var dataController: DataController
        
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
                            await self.transcribeRecordingFrom(data: data, for: response)
                        }//: TASK
                    @unknown default:
                        self.transcriptionErrorMessage = "Unable to transcribe audio due to an unknown authorization status for the Speech Recognition feature on your device. Please add this app to the list of approved apps in your device's Privacy & Security settings."
                        self.showTranscriptionErrorAlert = true
                    }//: SWITCH
                }//: TASK
            }//: requestAuthorization (closure)
        }//: requestTranscribingPermission()
        
        /// AudioReflectionRecorderViewModel method for creating a new transcripition of previously saved audio data for a specific
        /// ReflectionResponse object and then using that to update the ReflectionResponse's answer property.
        /// - Parameters:
        ///   - data: Data object representing audio binary data
        ///   - response: ReflectionResponse whose answer property is to be updated with the transcription
        ///
        /// - Important: This method does NOT update the Recording object previously saved in the ARDocument that
        /// was assigned to the ReflectionResponse object (as determined by the ARCoordinator).
        func transcribeRecordingFrom(data: Data, for response: ReflectionResponse) async {
            guard let selectedPrompt = response.question else {
                transcriptionErrorMessage = "The reflection this audio was recorded for does not have a specific prompt assigned to it. Please assign one and try again."
                NSLog(">>> Error trying to transcribe recording because the ReflectionResponse argument did not have an assigned ReflectionPrompt object to it.")
                showTranscriptionErrorAlert = true
                return
            }//: GUARD
            do {
                transcribingStatus = .transcribing
                let recordingData = try AVAudioPlayer(data: data)
                let recognizer = SFSpeechRecognizer()
                
                try recordingData.data?.write(to: tempTranscriptionURL)
                NSLog(">>> Saved audio data to temporary URL: \(tempTranscriptionURL.path)")
                
                let savedAudio = try Data(contentsOf: tempTranscriptionURL)
                if savedAudio.count > 0 {
                    let speechRequest = SFSpeechURLRecognitionRequest(url: tempTranscriptionURL)
                    speechRequest.addsPunctuation = true
                    speechRequest.requiresOnDeviceRecognition = true
                    speechRequest.shouldReportPartialResults = false
                    speechRequest.taskHint = .dictation
                    
                    recognizer?.recognitionTask(with: speechRequest) { result, error in
                        guard let result else {
                            Task{
                                await self.audioBrain.saveAudioReflectionWithoutTranscription(for: response, with: savedAudio, promptUsed: selectedPrompt)
                                
                            }//: TASK
                            
                            NSLog(">>> Error with the recognitionTask in transcribeRecordingFrom(data:) method.")
                            NSLog(">>> Error details: \(error?.localizedDescription ?? "No error details provided.")")
                            
                            Task{@MainActor in
                                self.transcriptionErrorMessage = "Failed to transcribe the audio. Will save the audio to disk if possible."
                                self.transcribingStatus = .error
                                self.showTranscriptionErrorAlert = true
                            }//: TASK
                            return
                        }//: GUARD
                        
                        let transcribedAnswer = result.bestTranscription.formattedString
                        
                        Task{@MainActor in
                            var recordingFilename: String = ""
                            var transcriptionFilename: String = ""
                            
                            if let questionText = selectedPrompt.question {
                                recordingFilename = questionText.trimWordsTo(length: 30) + "_response" + String.audioFormatExtension
                                transcriptionFilename = "transcription_\(questionText.trimWordsTo(length: 15)).txt"
                            } else {
                                let calendar = Calendar.current
                                let transcriptTime = Date.now
                                let yearComponent = calendar.component(.year, from: transcriptTime)
                                let monthComponent = calendar.component(.month, from: transcriptTime)
                                let dayComponent = calendar.component(.day, from: transcriptTime)
                                let transcriptStamp = "\(monthComponent)-\(dayComponent)-\(yearComponent)"
                                recordingFilename = "promptAudioResponse\(transcriptStamp)" + String.audioFormatExtension
                                transcriptionFilename = "transcription_\(transcriptStamp).txt"
                            }//: IF LET ELSE (questionText)
                            
                            let newRecording = Recording(
                                fileName: recordingFilename,
                                transcriptionFilename: transcriptionFilename,
                                transcription: transcribedAnswer
                            )
                            
                            do {
                                try await self.audioBrain.saveNewAudioReflection(
                                    for: response,
                                    with: savedAudio,
                                    promptUsed: selectedPrompt,
                                    recordingInfo: newRecording
                                )
                               
                                // Saving the transcription to the ReflectionResponse's answer property
                                response.answer = transcribedAnswer
                                self.dataController.save()
                                self.transcribingStatus = .completed
                            } catch {
                                NSLog(">>> Was able to successfully transcribe recorded audio, but failed to save the created ARDocument to disk.")
                                NSLog(">>> Error message: \(self.audioBrain.errorMessage)")
                                self.transcriptionErrorMessage = self.audioBrain.errorMessage
                                self.transcribingStatus = .error
                                self.showTranscriptionErrorAlert = true
                            }//: DO-CATCH
                        }//: TASK
                    }//: recognitionTask
                }//: IF (count)
            } catch {
                NSLog(">>> Error trying to transcribe existing recording.")
                NSLog(">>> Error details: \(error.localizedDescription)")
                transcribingStatus = .error
                transcriptionErrorMessage = "Unable to transcribe recorded audio data. Please try again."
                showTranscriptionErrorAlert = true
            }//: DO-CATCH
            
            if transcribingStatus == .completed {
                do {
                    try fileSystem.removeItem(at: tempTranscriptionURL)
                } catch {
                    NSLog(">>> Error deleting the recorded audio that was saved to the temporary directory for transcription purposes.")
                    NSLog(">>> The url used was: \(tempTranscriptionURL.absoluteString)")
                }//: DO-CATCH
            }//: IF (.completed)
        }//: transcribeRecordingFrom(data)
        
        /// AudioReflectionRecorderViewModel method for setting the value of a specific ReflectionResponse's answer property to
        /// be equal to the original transcription from the audio recording as previously saved in an ARDocument.
        /// - Parameter response: ReflectionResponse object for which the user wishes to revert the answer
        /// property back to what was originally transcribed when they first recorded an audio reflection.
        ///
        /// This method exists mainly for user convenience.  If a user has access to the audio reflections feature (as a Pro
        /// subscriber), then they record an audio answer for a selected CeActivity reflection prompt, only to later edit the text
        /// (as the answer property is a string) in the user interface.  Should they later wish to revert back to their original recording,
        /// then this method can be called for them to replace the ReflectionResponse answer String with what was transcribed from
        /// the original audio recording.
        func restoreOriginalTranscription(for response: ReflectionResponse) async {
            guard let matchedCoordinator = await audioBrain.findMatchingCoordinatorFor(response: response) else {
                NSLog(">>> Error finding a matching coordinator for the ReflectionResponse argument in restoreOriginalTranscription(for) method.")
                await MainActor.run {
                    transcriptionErrorTitle = "Transcription Error"
                    transcriptionErrorMessage = "Unable to restore the original transcription for the audio reflection due to missing file data."
                    showTranscriptionErrorAlert = true
                }//: MAIN ACTOR
                return
            }//: GUARD
            
            transcribingStatus = .transcribing
            let savedAudio = await ARDocument(audioURL: matchedCoordinator.fileURL)
            if await savedAudio.open() {
                let audioRecording = await savedAudio.audioRecordingInfo
                if audioRecording.transcription.count > 0 {
                    Task{@MainActor in
                        response.answer = audioRecording.transcription
                        self.dataController.save()
                        transcribingStatus = .completed
                    }//: TASK
                } else {
                    NSLog(">>> Error updating the ReflectionResponse answer property due to the transcription property within the ARDocument for the assigned ReflectionResponse being empty.")
                    await MainActor.run {
                        transcriptionErrorMessage = "The transcription file for the recorded audio is empty, so nothing could be restored."
                        transcriptionErrorTitle = "Transcription Error"
                        transcribingStatus = .error
                        showTranscriptionErrorAlert = true
                    }//: MAIN ACTOR
                }//: IF ELSE
                await savedAudio.close()
            } else {
                NSLog(">>> Error trying to open the ARDocument file at: \(matchedCoordinator.fileURL.absoluteString)")
                await MainActor.run {
                    transcriptionErrorTitle = "Transcription Error"
                    transcriptionErrorMessage = "Error encountered while trying to open the file where the recording data is saved."
                    transcribingStatus = .error
                    showTranscriptionErrorAlert = true
                }//: MAIN ACTOR
            }//: IF AWAIT (open)
        }//: restoreOriginalTranscription(for)
        
        
        // MARK: - INIT
        
        init(aBrain: AudioReflectionBrain, dataController: DataController) {
            self.audioBrain = aBrain
            self.dataController = dataController
            
        }//: INIT
        
    }//: VIEW MODEL
    
}//: EXTENSION

//
//  PromptResponseTextEntryView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import SwiftUI

struct PromptResponseTextEntryView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var audioData: AudioDataHolder
    @ObservedObject var response: ReflectionResponse
    
    @StateObject var viewModel: ViewModel
    
    // Various alerts
    @State private var showSwitchToAudioAlert: Bool = false
    
    let audioBrain: AudioReflectionBrain
    let dataController: DataController
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // MARK: Regular text entry view
            if viewModel.isProSubscriber, audioData.okToTranscribeAudio, viewModel.showTextEntryFields {
                VStack {
                    Image(systemName: "music.mic")
                        .font(.largeTitle)
                    Text("Answer Prompt with Audio")
                        .font(.title3)
                    Text("As a ProSubscriber, save your fingers from typing by using the audio reflection feature to record your answer. On-device speech recognition will be used to create and save a transcription of the audio which will show up here once completed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        audioData.okToTranscribeAudio = false
                    } label: {
                        Text("I'd rather just type...")
                    }//: BUTTON
                    .buttonStyle(.bordered)
                    .padding(.top, 15)
                }//: VSTACK
            } else if viewModel.isProSubscriber, viewModel.showTextEntryFields {
                VStack{
                    Text("Prompt Answer:")
                        .font(.title3)
                    TextField("Reflection text entry", text: $response.responseAnswer, axis: .vertical)
                        .frame(minHeight: 200)
                    Divider()
                    Button {
                       showSwitchToAudioAlert = true
                    } label: {
                        Text("Record audio response")
                    }//: BUTTON
                    .buttonStyle(.bordered)
                }//: VSTACK
            } else if viewModel.showTextEntryFields {
                VStack {
                    Text("Prompt Answer:")
                        .font(.title3)
                    TextField("Reflection text entry", text: $response.responseAnswer, axis: .vertical)
                        .frame(minHeight: 200)
                }//: VSTACK
            }//: IF ELSE
            
            // MARK: Transcription progress view
            if viewModel.transcribingStatus == .transcribing {
                VStack {
                    Text("Transcribing...")
                        .font(.headline)
                    ProgressView()
                        .progressViewStyle(.circular)
                }//: VSTACK
                .frame(width: 100, height: 100)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }//: IF (transcribingStatus == .transcribing)
            
            // MARK: Completed transcription w/ option to restore original
            if viewModel.transcribingStatus == .completed {
                VStack {
                    Text("Transcription:")
                        .font(.headline)
                    Text("Please note that on-device speech recognition may not transcribe all words with 100% accuracy, but you can edit the transcription text below as needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Transcribed Audio", text: $response.responseAnswer, axis: .vertical)
                        .frame(minHeight: 200)
                    Divider()
                    Button("Restore original transcription") {
                        Task{@MainActor in
                            await viewModel.restoreOriginalTranscription(for: response)
                        }//: TASK
                    }//: BUTTON
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.white)
                }//: VSTACK
            }//: IF (.completed)
            
        }//: VSTACK
        // MARK: - ALERTS
        .alert("Change to Audio Reflection", isPresented: $showSwitchToAudioAlert) {
            Button("OK") {
                response.responseAnswer = ""
                audioData.okToTranscribeAudio = true
            }//: BUTTON
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Switching to using the audio reflection feature will cause the loss of anything already typed for your prompt answer. Please confirm you are OK with this.")
        }//: ALERT
        
        .alert(viewModel.transcriptionErrorTitle, isPresented: $viewModel.showTranscriptionErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.transcriptionErrorMessage)
        }//: ALERT

        // MARK: - ON CHANGE
        .onChange(of: audioData.audioData) { data in
            // This allows the automatic transcribing of recorded audio when the user
            // gives permission for doing so (either via the general privacy setting in the
            // app or via the UI button for enabling it for this specific response
            if let recordedAudio = data, audioData.okToTranscribeAudio {
                viewModel.requestTranscribingPermission(data: recordedAudio, for: response)
            }
        }//: ON CHANGE
    }//: BODY
    
    // MARK: - INIT
    
    init(response: ReflectionResponse, audioBrain: AudioReflectionBrain, dataController: DataController) {
        self.response = response
        self.audioBrain = audioBrain
        self.dataController = dataController
        
        let newViewModel = ViewModel(aBrain: audioBrain, dataController: dataController)
        _viewModel = StateObject(wrappedValue: newViewModel)
        
        audioData.okToTranscribeAudio = dataController.allowsAutoTranscriptionOfAudio
        
    }//: INIT
    
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptResponseTextEntryView(response: .example, audioBrain: .preview, dataController: .preview)
}//: PREVIEw

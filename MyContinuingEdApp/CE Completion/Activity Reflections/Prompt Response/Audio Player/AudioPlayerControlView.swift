//
//  AudioPlayerControlView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/30/26.
//

import AVFoundation
import SwiftUI


struct AudioPlayerControlView: View {
    // MARK: - PROPERTIES
    
    @StateObject var viewModel: ViewModel
    
    @ObservedObject var response: ReflectionResponse
    
    let playerSymbols: [String: String] = [
        "play": "play.fill",
        "pause": "pause",
        "rewind15": "gobackward.15",
        "forward15": "goforward.15",
        "delete": "trash.fill"
    ]
    
    // Audio deletion
    @State private var showAudioDeletionWarning: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    
    var isPlaying: Bool {
        switch viewModel.audioPlayerStatus {
        case .playing:
            return true
        default:
            return false
        }//: SWITCH
    }//: isPlaying
    
    // MARK: - BODY
    var body: some View {
        if viewModel.audioPlayerStatus == .loading {
            VStack {
                Text("Loading audio...")
                ProgressView()
                    .progressViewStyle(.circular)
            }//: VSTACK
        } else {
            VStack {
                // MARK: - Progress Bar
                if let player = viewModel.audioPlayer {
                    AudioPlayerProgressBar(audioPlayer: player )
                }//: IF LET
                
                // MARK: - MAIN BUTTONS
                if let rewindIcon = playerSymbols["rewind15"], let forwardIcon = playerSymbols["forward15"], let pauseIcon = playerSymbols["pause"], let playIcon = playerSymbols["play"] {
                    HStack {
                        Spacer()
                        Group {
                            // MARK: 15 Seconds Reverse Button
                            Button {
                                viewModel.goBack(seconds: 15)
                            } label: {
                                Label("Go Back 15 Seconds", systemImage: rewindIcon)
                            }//: BUTTON
                            
                            // MARK: Play/Pause button
                            Button {
                                switch isPlaying {
                                case true:
                                    viewModel.pauseAudio()
                                case false:
                                    viewModel.playAudio(for: response)
                                }//: SWITCH
                            } label: {
                                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? pauseIcon : playIcon)
                            }//: BUTTON
                            
                            // MARK: Forward 15 Seconds Button
                            Button {
                                viewModel.goForward(seconds: 15)
                            } label: {
                                Label("Go Forward 15 Seconds", systemImage: forwardIcon)
                            }//: BUTTON
                        }//: GROUP
                        
                        Spacer()
                    }//: HSTACK
                    
                    // MARK: - DELETE BUTTON
                    HStack {
                        Spacer()
                        if let deleteIcon = playerSymbols["delete"] {
                            Button {
                                showAudioDeletionWarning = true
                            } label: {
                                Label("Delete Recording", systemImage: deleteIcon)
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(Color.red)
                            }//: BUTTON
                        }//: IF LET (deleteIcon)
                        Spacer()
                    }//: HSTACK
                     // MARK: - ALERTS
                    .alert("Delete Audio Reflection?", isPresented: $showAudioDeletionWarning) {
                        Button(role: .destructive) {
                            viewModel.deleteRecordedAudio()
                        } label: {
                            Text("Delete")
                        }//: BUTTON
                        
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you wish to delete the recorded audio for this prompt?")
                    }//: ALERT
                    
                }//: VSTACK
            }//: IF LET
        }//: IF - ELSE
    }//: BODY
    // MARK: - INIT
    
    init(response: ReflectionResponse) {
        self.response = response
        
        let newViewModel = ViewModel(response: response)
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
   
}//: STRUCT




//
//  AudioPlayerController_ViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import AVFoundation
import Foundation
import SwiftUI

extension AudioPlayerControlView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        @Published var audioPlayerStatus: PlaybackStatus = .loading
        
        var audioPlayer: AVAudioPlayer?
        enum PlaybackStatus { case loading, ready, playing, paused, stopped }
       
        // Playback errors
        @Published var showPlaybackError: Bool = false
        var playbackErrorAlertMessage: String = ""
        var playbackErrorAlertTitle: String = "Playback Error"
        
        // Other Needed Objects
        var audioBrain: AudioReflectionBrain
        let response: ReflectionResponse
        
        // MARK: - COMPUTED PROPERTIES
        
        var audioToPlayLocation: URL? {
            audioBrain.loadedAudio.first(where: { $0.key == response.id })?.value
        }//: audioToPlayLocation
        
        var audioEndsAt: TimeInterval {
            if let player = audioPlayer {
                return player.duration
            } else {
                return .zero
            }
        }//: audioEndsAt
        
        
        // MARK: - METHODS
        
        func playAudio(for response: ReflectionResponse) {
            if let responseID = response.id, let audioLocation: URL = audioToPlayLocation {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: audioLocation)
                    if let player = audioPlayer {
                        player.prepareToPlay()
                        audioPlayerStatus = .playing
                        player.play()
                    }//: IF LET
                } catch {
                    NSLog(">>> Error playing audio at the url: \(audioLocation.absoluteString)")
                    NSLog(">>> Details: \(error.localizedDescription)")
                    playbackErrorAlertMessage = "Encountered an error while trying to play the recorded audio for this prompt."
                    showPlaybackError = true
                }//: DO-CATCH
                
            } else {
                NSLog(">>> Error: No audio file found for this response.")
                NSLog(">>> Specifically, either a response id key was not found in the loadedAudio dictionary or a URL was not associated with that key. It's also possible that the response id property is nil.")
                playbackErrorAlertMessage = "Unable to locate the recorded audio for this prompt."
                showPlaybackError = true
            }//: IF ELSE
        }//: playAudio()
        
        func pauseAudio() {
            guard let player = audioPlayer else {
                NSLog(">>> Error pausing audio due to a nil audioPlayer property value.")
                return
            }//: GUARD
            player.pause()
            audioPlayerStatus = .paused
        }//: pauseAudio()
        
        func stopAudioPlayback() {
            guard let player = audioPlayer else { return }
            
            player.stop()
            player.currentTime = 0
            audioPlayerStatus = .stopped
        }//: stopAudioPlayback()
        
        func goBack(seconds: Double) {
            guard let player = audioPlayer else { return }
            let newTime = player.currentTime - seconds
            player.play(atTime: newTime)
        }//: goBack(seconds)
        
        func goForward(seconds: Double) {
            guard let player = audioPlayer else { return }
            let newTime = player.currentTime + seconds
            player.play(atTime: newTime)
        }//: goForward(seconds)
        
        func deleteRecordedAudio() {
            Task{
                do {
                    try await audioBrain.deleteAudioReflection(for: response)
                } catch {
                    NSLog(">>> Error attempting to delete the audio saved for a particular response.")
                    playbackErrorAlertTitle = "Deletion Error"
                    playbackErrorAlertMessage = "An error was encountered while trying to delete the saved audio file."
                    showPlaybackError = true
                }//: DO-CATCH
            }//: TASK
        }//: deleteRecordedAudio()
        
        
        // MARK: - INIT
        
        init(
            aBrain: AudioReflectionBrain,
            response: ReflectionResponse
        ) {
            self.audioBrain = aBrain
            self.response = response
            
            Task{@MainActor in
                do {
                    audioPlayerStatus = .loading
                    try await audioBrain.loadSavedAudioReflection(for: response)
                    audioPlayerStatus = .ready
                } catch {
                    playbackErrorAlertMessage = "Encountered an error while trying to load the saved audio data for this response."
                    showPlaybackError = true
                }//: DO-CATCH
            }//: TASK
        }//: INIT
        
    }//: CLASS
    
}//: EXTENSION

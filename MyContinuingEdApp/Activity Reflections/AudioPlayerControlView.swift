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
    
    @State private var isPlaying: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
    let playerSymbols: [String: String] = [
        "play": "play.fill",
        "pause": "pause",
        "rewind15": "gobackward.15",
        "forward15": "goforward.15",
        "delete": "trash.fill"
    ]
    
    // MARK: - BODY
    var body: some View {
        
        
        
        
        // MARK: - MAIN BUTTONS
        if let rewindIcon = playerSymbols["rewind15"], let forwardIcon = playerSymbols["forward15"], let pauseIcon = playerSymbols["pause"], let playIcon = playerSymbols["play"] {
            HStack {
                Spacer()
                Group {
                    // MARK: 15 Seconds Reverse Button
                    Button {
                        // TODO: Add action(s)
                    } label: {
                        Label("Go Back 15 Seconds", systemImage: rewindIcon)
                    }//: BUTTON
                    
                    // MARK: Play/Pause button
                    Button {
                        // TODO: Add action(s)
                    } label: {
                        Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? pauseIcon : playIcon)
                    }//: BUTTON
                    
                    // MARK: Forward 15 Seconds Button
                    Button {
                        // TODO: Add action(s)
                    } label: {
                        Label("Go Forward 15 Seconds", systemImage: forwardIcon)
                    }//: BUTTON
                }//: GROUP
                
                Spacer()
                
                if let deleteIcon = playerSymbols["delete"] {
                    Button {
                        // TODO: Add action(s)
                    } label: {
                        Label("Delete Recording", systemImage: deleteIcon)
                    }//: BUTTON
                }//: IF LET
            }//: HSTACK
        }//: IF LET
        
    }//: BODY
   
}//: STRUCT


// MARK: - COORDINATOR


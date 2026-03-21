//
//  AudioPlayerProgressBar.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import AVFoundation
import SwiftUI

struct AudioPlayerProgressBar: View {
    // MARK: - PROPERTIES
    
    @State var audioPlayer: AVAudioPlayer? = nil
    
    // MARK: - COMPUTED PROPERTIES
    
    var totalTime: TimeInterval { audioPlayer?.duration ?? 0 }//: totalTime
    var currentTime: TimeInterval { audioPlayer?.currentTime ?? 0 }//: currentTime
    
    var playedTime: String {
        if currentTime <= 60 {
            return String(format: "%02d", currentTime)
        } else if (currentTime / 60) <= 3600 {
            let minutes = currentTime.truncatingRemainder(dividingBy: 60)
            let seconds = currentTime - (minutes * 60)
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            let hours = currentTime.truncatingRemainder(dividingBy: 3600)
            let minutes = (currentTime - (hours * 3600)).truncatingRemainder(dividingBy: 60)
            let seconds = currentTime - (hours * 3600) - (minutes * 60)
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }//: IF ELSE
    }//: STRING
    
    var remainingTime: String {
        let unplayedTime = totalTime - currentTime
        
        if unplayedTime <= 60 {
            return String(format: "%-02d", unplayedTime)
        } else if (unplayedTime / 60) <= 3600 {
            let minutes = unplayedTime.truncatingRemainder(dividingBy: 60)
            let seconds = unplayedTime - (minutes * 60)
            return String(format: "%-02d:%-02d", minutes, seconds)
        } else {
            let hours = unplayedTime.truncatingRemainder(dividingBy: 3600)
            let minutes = (unplayedTime - (hours * 3600)).truncatingRemainder(dividingBy: 60)
            let seconds = unplayedTime - (hours * 3600) - (minutes * 60)
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }//: IF ELSE
    }//: remainingTime
    
    // MARK: - BODY
    var body: some View {
        VStack {
            // Time values
            HStack {
                Text(playedTime)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(remainingTime)
                    .foregroundStyle(.secondary)
            }//: HSTACK
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 25)
                        .foregroundStyle(Color(.systemGray4))
                        .shadow(radius: 2)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .frame(
                            width: CGFloat(currentTime / totalTime) * geo.size.width.scaled(by: 0.9),
                            height: 25
                        )
                        .foregroundStyle(Color(.systemBlue))
                }//: ZSTACK
                .frame(height: 25)
            }//: GEO READER
        }//: VSTACK
        .accessibilityHint(Text("Audio player progress bar that shows how much of the file has been played."))
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    AudioPlayerProgressBar()
}

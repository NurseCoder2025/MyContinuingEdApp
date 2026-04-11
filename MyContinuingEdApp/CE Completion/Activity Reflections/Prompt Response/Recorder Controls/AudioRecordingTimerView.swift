//
//  AudioRecordingTimerView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/20/26.
//

import SwiftUI

struct AudioRecordingTimerView: View {
    // MARK: - PROPERTIES
    @State var recordingTime: TimeInterval = .zero
    
    private let timerValuerFormat: String = "%02d"
    
    // MARK: - COMPUTED PROPERTIES
    
    private var hoursRecorded: String {
        let totalHours = Int(recordingTime / 3600)
        if totalHours < 1 {
            return "00"
        } else {
            return String(format: timerValuerFormat, totalHours)
        }
    }//: hoursRecorded
    
    private var minutesRecorded: String {
        let totalMinutes = Int(recordingTime / 60)
        if totalMinutes < 1 {
            return "00"
        } else {
            return String(format: timerValuerFormat, totalMinutes)
        }
    }//: minutesRecorded
    
    private var secondsRecorded: String {
        let totalSeconds = Int(recordingTime.truncatingRemainder(dividingBy: 60))
        return String(format: timerValuerFormat, totalSeconds)
    }//: secondsRecorded
    
    // MARK: - BODY
    var body: some View {
        Group {
            HStack(spacing: 5) {
                Text(hoursRecorded)
                Text(":")
                Text(minutesRecorded)
                Text(":")
                Text(secondsRecorded)
            }//: HSTACK
        }//: GROUP
        .font(.headline)
        .accessibilityHint(Text("Recording Time"))
    }//: BODY
    
}//: STRUCt

// MARK: - PREVIEW
#Preview {
    AudioRecordingTimerView()
}

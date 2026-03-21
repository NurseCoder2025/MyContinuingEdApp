//
//  RecordAudioButtonView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/20/26.
//

import SwiftUI

struct RecordAudioButtonView: View {
    // MARK: - PROPERTIES
    
    @State var recordingState: RecordingStatus = .waiting
    
    let outerCircleWidth: CGFloat = 120
    let outerCircleHeight: CGFloat = 120
    
    // MARK: - COMPUTED PROPERTIES
    
    private var innerItemLarge: CGFloat { outerCircleWidth - 10 }//: innerItemLarge
    
    private var innerItemMedium: CGFloat { outerCircleWidth - 35 }//: innterItemMedium
    
    // MARK: - BODY
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: 3)
                    .foregroundStyle(Color.clear)
                    .frame(width: outerCircleWidth, height: outerCircleHeight)
                    .accessibilityHidden(true)
                
                switch recordingState {
                case .waiting:
                    Circle()
                        .foregroundStyle(Color.red)
                        .frame(width: innerItemLarge, height: innerItemLarge)
                        .accessibilityHint(Text("Start recording audio reflection"))
                case .recording:
                    Image(systemName: "pause.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.red)
                        .frame(width: innerItemMedium, height: innerItemMedium)
                        .accessibilityHint(Text("Pause recording"))
                case .paused:
                    Image(systemName: "mic.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.red)
                        .frame(width: innerItemMedium, height: innerItemMedium)
                        .accessibilityHint(Text("Resume recording"))
                case .stopped:
                    Circle()
                        .foregroundStyle(Color.red)
                        .frame(width: innerItemLarge, height: innerItemLarge)
                        .accessibilityHint(Text("Start new recording"))
                case .error:
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.red)
                        .frame(width: innerItemMedium, height: innerItemMedium)
                        .accessibilityHint(Text("Error encountered while recording. Recording stopped."))
                }//: SWITCH
            }//:ZSTACK
            
            if recordingState == .paused {
                Text("Continue Recording...")
                    .foregroundStyle(Color.red)
                    .padding(.top, 10)
            }//: IF
            
        }//: VSTACK
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    RecordAudioButtonView()
}

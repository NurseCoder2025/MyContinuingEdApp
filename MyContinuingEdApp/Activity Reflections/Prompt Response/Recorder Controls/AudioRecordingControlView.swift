//
//  AudioRecordingControlView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import AVFoundation
import SwiftUI

struct AudioRecordingControlView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var audioData: AudioDataHolder
       
    @StateObject var viewModel: ViewModel
    
    @State private var recordingElapsedTime: TimeInterval = .zero
    
    // MARK: - BODY
    var body: some View {
            VStack {
                // MARK: Time Elapse Counter
                AudioRecordingTimerView(recordingTime: recordingElapsedTime)
                
                // MARK: Recording volume bar
                HStack(spacing: 2) {
                    ForEach(viewModel.audioBars) { bar in
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(bar.barColor)
                            .frame(width: bar.powerBarWidth, height: bar.powerBarHeight)
                            .animation(.easeIn, value: bar.powerBarWidth)
                        }//: ForEACH
                }//: HSTACK
                .frame(maxHeight: 30)
                
                // MARK: BUTTONS
                HStack(alignment: .center) {
                    Spacer()
                    
                    // MARK: Recording control button
                    Button {
                        // For starting and pausing the recording
                        // Decided to use a separate button for ending the recording for
                        // better user experience and convenience
                        viewModel.changeRecordingAction()
                    } label: {
                        RecordAudioButtonView(recordingState: viewModel.recordingStatus)
                    }//: BUTTON
                    
                    // MARK: End recording button
                    if viewModel.recordingStatus == .recording || viewModel.recordingStatus == .paused {
                        Button {
                            viewModel.stopRecording()
                            audioData.audioData = try? Data(contentsOf: viewModel.tempRecordingURL)
                        } label: {
                            Label("Stop Recording", image: "stop.fill")
                                .foregroundStyle(Color.white)
                        }//: BUTTON
                        .buttonStyle(.borderedProminent)
                    }//: IF (.recording)
                    
                    Spacer()
                }//: HSTACK
                
            }//: VSTACK
        // MARK: - ON CHANGE (recording)
        .onChange(of: viewModel.recordingStatus) { status in
            while status == RecordingStatus.recording || status == RecordingStatus.paused {
                recordingElapsedTime = viewModel.elapsedRecordingTime
            }//: WHILE
        }//: ON CHANGE
        
        .onChange(of: viewModel.elapsedRecordingTime) {_ in
            viewModel.createNewAudioMetricBar()
        }//: ON CHANGE
        
        // MARK: - ALERTS
        .alert(viewModel.recordingErrorTitle, isPresented: $viewModel.showRecordingErrorAlert) {
            Button("OK"){}
        } message: {
            Text(viewModel.recordingErrorMessage)
        }//: ALERT

    }//: BODY
    
    // MARK: - INIT
    init() {
        let newViewModel = ViewModel()
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    AudioRecordingControlView()
}//: PREVIEW

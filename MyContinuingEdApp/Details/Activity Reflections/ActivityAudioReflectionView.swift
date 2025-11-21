//
//  ActivityAudioReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/20/25.
//

import AVFoundation
import SwiftUI

struct ActivityAudioReflectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var settings: CeAppSettings
    @ObservedObject var reflection: ActivityReflection
    
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayerDelegate: AudioPlayerDelegateWrapper?
    @State private var recordingURL: URL?
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        settings.settings.appPurchaseStatus
    }
    
    // MARK: - BODY
    var body: some View {
        if paidStatus != .proSubscription {
            PaidFeaturePromoView(
                featureIcon: "waveform.and.mic",
                featureItem: "Audio Reflection",
                featureUpgradeLevel: .ProOnly
            )
        } else {
            // MARK: Audio Section
            Section("Audio Reflection") {
                HStack(spacing: 8) {
                    if reflection.audioReflections != nil {
                        Button {
                            if isPlaying {
                                audioPlayer?.stop()
                                isPlaying = false
                            } else {
                                playAudio()
                            }
                        } label: {
                            Label(
                                isPlaying ? "Stop Playback" : "Play Audio",
                                systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill"
                            )
                            .labelStyle(.iconOnly)
                            .foregroundStyle(isPlaying ? .red : .blue)
                        }
                    }//: If (no audio reflection data)
                    
                    Button {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        Label(
                            isRecording ? "Stop Recording" : "Record Audio",
                            systemImage: isRecording ? "stop.circle.fill" : "mic"
                        )
                        .labelStyle(.iconOnly)
                        .foregroundStyle(isRecording ? .red : .blue)
                    }
                }//: HSTACK
            }//: SECTION - Audio Reflection
        }//: IF ELSE
    }//: BODY
    
    // MARK: - FUNCTIONS
    func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingURL = fileURL
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        if let url = recordingURL {
            do {
                let data = try Data(contentsOf: url)
                reflection.audioReflections = data
            } catch {
                print("Failed to save audio data: \(error)")
            }
        }
    }
    
    func playAudio() {
        guard let audioData = reflection.audioReflections else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayerDelegate = AudioPlayerDelegateWrapper { isPlaying = false }
            audioPlayer?.delegate = audioPlayerDelegate
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    
}//: STRUCT


// MARK: - Helper for AVAudioPlayer delegate
class AudioPlayerDelegateWrapper: NSObject, AVAudioPlayerDelegate {
    var onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}


// MARK: - PREVIEW
#Preview {
    ActivityAudioReflectionView(reflection: .example)
}

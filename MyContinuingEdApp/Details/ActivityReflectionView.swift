//
//  ActivityReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import SwiftUI
import AVFoundation

struct ActivityReflectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    var activity: CeActivity
    @ObservedObject var reflection: ActivityReflection
    
    // Audio Recording/Playback
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayerDelegate: AudioPlayerDelegateWrapper?
    @State private var recordingURL: URL?
    
    // MARK: - BODY
    var body: some View {
        Form {
            Section {
                Text("Reflections on \(activity.ceTitle)")
                    .font(.largeTitle)
            }//: HEADER SECTION
            
            Section("3 Main Points") {
                TextField(
                    "Three main points summary",
                    text: $reflection.reflectionThreeMainPoints,
                    prompt: Text("Summarize the 3 main points of this activity"),
                    axis: .vertical
                )
                    .font(.title3)
                
            }//: SECTION - Summarize
            
            Section("New & Surprising Info") {
                Toggle("Were you surprised by anything you learned?", isOn: $reflection.wasSurprised)
                
                if reflection.wasSurprised {
                    TextField(
                        "Anything surprising",
                        text: $reflection.reflectionSurprises,
                        prompt: Text("Did you learn anything that surprised you during the activity?"),
                        axis: .vertical
                )
                .font(.title3)
                } //: IF - was surprised
            }//: SECTION - Surprising learning
            
            Section("Going Further") {
                TextField(
                    "Want to learn more about what",
                    text: $reflection.reflectionLearnMoreAbout,
                    prompt: Text("What would you like to learn more about on from this activity?"),
                    axis: .vertical
                )
                    .font(.title3)
                
            }//: SECTION - More to learn
            
            Section("Other Reflections") {
                TextField(
                    "Other thoughts",
                    text: $reflection.reflectionGeneralReflection,
                    prompt: Text("Do you have any other reflections or thoughts regarding this activity?"),
                    axis: .vertical
                )
                    .font(.title3)
                
            }//: SECTION - General thoughts
            
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
            
        }//: FORM
        // MARK: - AUTO SAVING FUNCTIONS
                .onSubmit {dataController.save()}
                .onReceive(reflection.objectWillChange) { _ in
                    dataController.queueSave()
                }//: ON RECEIVE
        
        // MARK: - ON DISAPPEAR
                .onDisappear {
                    dataController.save()
                }//: ON DISAPPEAR
            
    } //: BODY
    
    // MARK: - AUDIO FUNCTIONS
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
}

// Helper for AVAudioPlayer delegate
class AudioPlayerDelegateWrapper: NSObject, AVAudioPlayerDelegate {
    var onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}


// MARK: - PREVIEW
struct ActivityReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReflectionView(activity: .example, reflection: .example)
            
    }
}

//
//  MediaStorageSettingsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/10/26.
//

import SwiftUI

struct MediaStorageSettingsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @State private var certSaveToICloudPreference: Bool
    @State private var audioSaveToICloudPreference: Bool
    
    // MARK: Alert properties
    @State private var showCertSavePrefChangeAlert: Bool = false
    @State private var showAudioSavePrefChangeAlert: Bool = false
    
    @State private var certChangeAlertTitle: String = ""
    @State private var certChangeAlertMessage: String = ""
    
    @State private var audioChangeAlertTitle: String = ""
    @State private var audioChangeAlertMessage: String = ""

    // MARK: - BODY
    var body: some View {
        GroupBox {
            VStack {
                Text("CE Certificate Storage")
                    .font(.headline).bold()
                    .padding(.bottom, 5)
                
                Toggle("Save to iCloud?", isOn: $certSaveToICloudPreference)
                
                Divider()
                
                Text("Audio Reflections Storage")
                    .font(.headline).bold()
                    .padding(.bottom, 5)
                
                Toggle("Save to iCloud?", isOn: $audioSaveToICloudPreference)
            }//: VSTACK
        } label: {
            GroupBoxLabelView(
                labelText: "Media Storage",
                labelImage: "externaldrive.badge.icloud"
            )
        }//: GROUP BOX
        
        // MARK: - ON CHANGE
        .onChange(of: certSaveToICloudPreference) { certPreference in
            switch certPreference {
            case true:
                certChangeAlertTitle = "Save to iCloud?"
                certChangeAlertMessage = "This will move all locally saved certificates to iCloud. Please allow time for them to be uploaded."
            case false:
                certChangeAlertTitle = "Remove from iCloud?"
                certChangeAlertMessage = "WARNING: This will move all certificates from iCloud back to your local device. They will no longer be accessible from your other devices."
            }//: SWITCH
            
            showCertSavePrefChangeAlert = true
        }//: ON CHANGE (prefersCertificatesInICloud)
        
        .onChange(of: audioSaveToICloudPreference) { audioPref in
            switch audioPref {
                case true:
                    audioChangeAlertTitle = "Save to iCloud?"
                    audioChangeAlertMessage = "This will move all locally saved audio files to iCloud. Please allow time for them to be uploaded."
                case false:
                    audioChangeAlertTitle = "Remove from iCloud?"
                    audioChangeAlertMessage = "WARNING: This will move all audio reflections from iCloud back to your local device. They will no longer be accessible from your other devices."
            }//: SWITCH
            
            showAudioSavePrefChangeAlert = true
        }//: ON CHANGE (prefersAudioReflectionsInICloud)
        
        // MARK: - ALERTS
        .alert(certChangeAlertTitle, isPresented: $showCertSavePrefChangeAlert) {
            Button("OK") {
                dataController.prefersCertificatesInICloud = certSaveToICloudPreference
            }//: OK closure
            Button("Cancel", role: .cancel) {
                // Reversing toggle control's value to the original saved setting
                certSaveToICloudPreference = dataController.prefersCertificatesInICloud
            }//: CANCEL
        } message: {
            Text(certChangeAlertMessage)
        }//: ALERT (certChangeAlert)
        
        .alert(audioChangeAlertTitle, isPresented: $showAudioSavePrefChangeAlert) {
            Button("OK") {
                dataController.prefersAudioReflectionsInICloud = audioSaveToICloudPreference
            }//: OK
            Button("Cancel", role: .cancel) {
                audioSaveToICloudPreference = dataController.prefersAudioReflectionsInICloud
            }//: CANCEL
        } message: {
            Text(audioChangeAlertMessage)
        }//: ALERT
    }//: BODY
    
    // MARK: - INIT
    init(dataController: DataController) {
        _certSaveToICloudPreference = State(initialValue: dataController.prefersCertificatesInICloud)
        _audioSaveToICloudPreference = State(initialValue: dataController.prefersAudioReflectionsInICloud)
    }//: INIT
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    let dcPreview = DataController.preview
    MediaStorageSettingsView(dataController: dcPreview)
}

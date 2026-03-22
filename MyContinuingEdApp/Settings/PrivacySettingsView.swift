//
//  PrivacySettingsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import SwiftUI

struct PrivacySettingsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - BODY
    var body: some View {
        GroupBox {
            Toggle("Audio Auto Transcription", isOn: $dataController.allowsAutoTranscriptionOfAudio)
            DisclosureGroup("Transcription Info") {
                Text("CE Cache only uses on-device speech recognition technology to automatically transcribe audio reflections that you make in order to better protect your privacy. However, you can disable this feature and manually elect when to transcribe them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }//: DISCLOSURE GROUP
        } label: {
            SettingsHeaderView(headerText: "Privacy", headerImage: "hand.raised.fill")
        }//: GROUP BOX
    }//: BODY
}//: STUCT


// MARK: - PREVIEW
#Preview {
    PrivacySettingsView()
}

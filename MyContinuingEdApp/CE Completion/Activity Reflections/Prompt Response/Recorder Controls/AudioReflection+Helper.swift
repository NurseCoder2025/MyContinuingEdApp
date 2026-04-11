//
//  AudioReflection+Helper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/21/26.
//

import Foundation
import SwiftUI


final class AudioDataHolder: ObservableObject {
    @Published var okToTranscribeAudio: Bool = true
    @Published var audioData: Data?
}//: CLASS

//
//  AudioReflectionHelpers.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/18/26.
//

import Foundation
import SwiftUI


private struct AudioReflectionBrainKey: EnvironmentKey {
    static let defaultValue: AudioReflectionBrain? = nil
}//: STRUCT


extension EnvironmentValues {
    var audioBrain: AudioReflectionBrain? {
        get {
            self[AudioReflectionBrainKey.self]
        } set {
            self[AudioReflectionBrainKey.self] = newValue
        }
    }//: audioBrain
}//: EXTENSION

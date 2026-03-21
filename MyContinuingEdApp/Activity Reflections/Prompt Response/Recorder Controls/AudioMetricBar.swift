//
//  AudioRecordingVolumeBarView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/20/26.
//

import AVFoundation
import SwiftUI

struct AudioMetricBar: Identifiable {
    // MARK: - PROPERTIES
    let id: UUID = UUID()
    let audioPeakPower: Float
    let barColor: AudioBarColor
    
    // MARK: - COMPUTED PROPERTIES
    
    var powerBarHeight: CGFloat {
        let normalizedHeight = abs(audioPeakPower)
        let upperLimit: CGFloat = 160
        let maxDiff: CGFloat = 25
        let maxHeight: CGFloat = 25
       
        let difference = CGFloat(normalizedHeight) - 0
        let height: CGFloat = maxHeight - ((difference / upperLimit) * maxDiff)
        return height
    }//: powerBarFrameHeight
    
    var powerBarWidth: CGFloat {
        if audioPeakPower >= -160 && audioPeakPower <= -100 {
            return CGFloat(10)
        } else if audioPeakPower > -100 && audioPeakPower <= -50 {
            return CGFloat(15)
        } else if audioPeakPower > -50 && audioPeakPower < -20 {
            return CGFloat(20)
        } else {
            return CGFloat(25)
        }//: IF ELSE
    }//: powerBarWidth
    
    // MARK: - INIT
    
    init (power: Float, barColor: AudioBarColor = AudioBarColor(preferredColor: .orange)) {
        self.audioPeakPower = power
        self.barColor = barColor
    }//: INIT
    
}//: STRUCT



struct AudioBarColor: ShapeStyle {
    let preferredColor: Color
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        return preferredColor
    }//: resolve(in)
}//: STRUCT


//
//  SettingsSliderView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/18/25.
//

import SwiftUI

struct SettingsSliderView: View {
    // MARK: - PROPERTIES
    @Binding var sliderValue: Double
    
    // Properties for configuring the slider control
    let minValue: Double
    let maxValue: Double
    let stepValue: Int
    let headerText: String
    let minImageLabel: String
    let maxImageLabel: String
    
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(headerText): \(sliderValue, specifier: "%.0f") days")
                    .font(.headline)
                Spacer()
            }//: HSTACK
            
            Slider(
                value: $sliderValue,
                in: minValue...maxValue
            ) {
            
            } minimumValueLabel: {
                Image(systemName: minImageLabel)
            } maximumValueLabel: {
                Image(systemName: maxImageLabel)
            }
            
            
            HStack {
                Text("\(minValue, specifier: "%.0f") days")
                    .padding(.leading, 8)
                    .foregroundStyle(.secondary)
                    .accessibilityHint(Text("This is the earliest you can set this alert to be set for."))
                Spacer()
                Text("\(maxValue, specifier: "%.0f") days")
                    .padding(.trailing, 8)
                    .foregroundStyle(.secondary)
                    .accessibilityHint(Text("This is the latest you can set this alert to be set for."))
            }//: HSTACK
            
        }//: VSTACK
        .padding([.leading, .trailing], 20)
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    SettingsSliderView(
        sliderValue: .constant(30.0),
        minValue: 30.0,
        maxValue: 180.0,
        stepValue: 1,
        headerText: "Primary Alert",
        minImageLabel: "hourglass.bottomhalf.fill",
        maxImageLabel: "hourglass.tophalf.fill"
    )
}

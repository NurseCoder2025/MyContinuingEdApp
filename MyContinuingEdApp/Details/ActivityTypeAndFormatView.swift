//
//  ActivityTypeAndFormatView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/29/25.
//

// Purpose: To show the UI controls for the CE Activity's type and format sections within the
// parent view (ActivityView) so that the code is more maintanable

import CoreData
import SwiftUI

struct ActivityTypeAndFormatView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    // Properties for storing values for various activity fields
    @State private var selectedActivityType: ActivityType?
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.typeName)]) var allActivityTypes: FetchedResults<ActivityType>
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: Activity Type
            Section("Activity Type") {
                Picker("Type:", selection: $selectedActivityType) {
                    ForEach(allActivityTypes) { type in
                        Text(type.activityTypeName)
                            .tag(type as ActivityType?)
                    }//: LOOP
                    
                }//: PICKER
                .onChange(of: selectedActivityType) { newType in
                    activity.type = newType
                }
                
            }//: SECTION
            
            // MARK: Activity Format
            Section("Activity Format") {
                Picker("Format", selection: $activity.ceActivityFormat) {
                    ForEach(ActivityFormat.allFormats) {format in
                        HStack {
                            Image(systemName: format.image)
                            Text(format.formatName)
                        }//: HSTACK
                        .tag(format.formatName)
                    }//: LOOP
                    
                }//: PICKER
                .pickerStyle(.wheel)
                .frame(height: 100)
            }//: SECTION
            
        }//: GROUP
        // MARK: - ON APPEAR
        .onAppear {
            selectedActivityType = activity.type
        }
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ActivityTypeAndFormatView(activity: .example)
}

//
//  ActivityReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import SwiftUI

struct ActivityReflectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var settings: CeAppSettings
    
    var activity: CeActivity
    @ObservedObject var reflection: ActivityReflection
    
    // MARK: - BODY
    var body: some View {
        Form {
            ActivityAudioReflectionView(reflection: reflection)
            
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
    
}//: STRUCT


// MARK: - PREVIEW
struct ActivityReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReflectionView(activity: .example, reflection: .example)
            
    }
}

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
    
    var activity: CeActivity
    @ObservedObject var reflection: ActivityReflection
    
   
    
    // MARK: - BODY
    var body: some View {
        NavigationStack {
                Form {
                    Section {
                        Text("Reflections on \(activity.ceTitle)")
                            .font(.headline)
                    }//: HEADER SECTION
                    
                    Section("3 Main Points") {
                        TextField(
                            "Three main points summary",
                            text: $reflection.reflectionThreeMainPoints,
                            prompt: Text("Summarize the 3 main points of this activity")
                        )
                            .font(.title3)
                        
                    }//: SECTION - Summarize
                    
                    Section("New & Surprising Info") {
                        Toggle("Were you surprised by anything you learned?", isOn: $reflection.wasSurprised)
                        
                        if reflection.wasSurprised {
                            TextField(
                                "Anything surprising",
                                text: $reflection.reflectionSurprises,
                                prompt: Text("Did you learn anything that surprised you during the activity?")
                            )
                            .font(.title3)
                        } //: IF - was surprised
                    }//: SECTION - Surprising learning
                    
                    Section("Going Further") {
                        TextField(
                            "Want to learn more about what",
                            text: $reflection.reflectionLearnMoreAbout,
                            prompt: Text("What would you like to learn more about on from this activity?")
                        )
                            .font(.title3)
                        
                    }//: SECTION - More to learn
                    
                    Section("Other Reflections") {
                        TextField(
                            "Other thoughts",
                            text: $reflection.reflectionGeneralReflection,
                            prompt: Text("Do you have any other reflections or thoughts regarding this activity?")
                        )
                            .font(.title3)
                        
                    }//: SECTION - General thoughts
                    
                    
                }//: FORM
                .onReceive(reflection.objectWillChange) { _ in
                    dataController.queueSave()
                }
            
        }//: NAV STACK
    } //: BODY
}


// MARK: - PREVIEW
struct ActivityReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReflectionView(activity: .example, reflection: .example)
            
    }
}

//
//  ActivityReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/28/25.
//

import CoreData
import SwiftUI

struct ActivityReflectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    var activity: CeActivity
    @ObservedObject var reflection: ActivityReflection
    
    @State private var showPromptSelectionSheet: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var responsesCount: Int {return reflection.reflectionResponses.count}//: responsesCount
    
    var currentResponses: [ReflectionResponse] {
        return reflection.reflectionResponses
    }//: currentResponses
    
    var paidAppStatus: PurchaseStatus {
        let statusString = dataController.purchaseStatus
        switch statusString {
        case "basicUnlock":
            return PurchaseStatus.basicUnlock
        case "proSubscription":
            return PurchaseStatus.proSubscription
        default:
            return PurchaseStatus.free
        }//: SWITCH
    }//: paidAppStatus
    
    // MARK: - BODY
    var body: some View {
        Form {
            ActivityAudioReflectionView(reflection: reflection)
            
            Section {
                Text("Reflections on \(activity.ceTitle)")
                    .font(.largeTitle)
                Text("To complete this reflection, please select and respond to one prompt.")
            }//: HEADER SECTION
            
            Section("Learning Prompts") {
                // Prompt Selection
                Menu {
                    Button {
                        createRandomPrompt()
                    } label: {
                        Text("Random Prompt")
                    }//: BUTTON
                    
                    Button {
                        showPromptSelectionSheet = true
                    } label: {
                        Text("Let Me Choose")
                    }//: BUTTON
                } label: {
                    Text(responsesCount > 0 ? "Add Another Prompt" : "Add Prompt")
                }//: MENU
                
                // PromptResponseViews
                ForEach(currentResponses) { response in
                    PromptResponseView(response: response) {
                        showPromptSelectionSheet = true
                    }
                }//: LOOP
                
            }//: SECTION
            
            DisclosureGroup("New & Surprising Info") {
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
            }//: DISCLOSURE GROUP - Surprising learning
            
            DisclosureGroup("Other Reflections") {
                TextField(
                    "Other thoughts",
                    text: $reflection.reflectionGeneralReflection,
                    prompt: Text("Do you have any other reflections or thoughts regarding this activity?"),
                    axis: .vertical
                )
                .font(.title3)
            }//: DISCLOSURE GROUP - General thoughts
            
        }//: FORM
         // MARK: - AUTO SAVING FUNCTIONS
        .onReceive(reflection.objectWillChange) { _ in
            dataController.queueSave()
        }//: ON RECEIVE
        
        // MARK: - ON DISAPPEAR
        .onDisappear {
            // TODO: Figure out why I need to call the showActivityReflectionView
            dataController.showActivityReflectionView = false
            dataController.save()
        }//: ON DISAPPEAR
        
    } //: BODY
    
    // MARK: - METHODS
    
    func reflectionCompleted() -> Bool {
        // TODO: Update logic and return
        let mainPointSummaryCount = reflection.reflectionThreeMainPoints.count
        return false
    }//: reflectionCompleted()
    
    /// Method part of ActivityReflectionView that returns a randomized reflection response object for a user who wants it.  This method is
    /// called when the "Random Prompt" button is tapped in the menu in ActivityReflectionView > Learning Prompts section.
    /// - Returns: random ReflectionResponse object
    ///
    /// - Note: The randomization is used to assign a random prompt (if the user is a subscriber, then any custom prompts will be included)
    /// to the creation of a new ReflectionResponse object, which has a ReflectionPrompt object as one of its relationship properties.
    func createRandomPrompt() {
        let context = dataController.container.viewContext
        let promptFetch = ReflectionPrompt.fetchRequest()
        promptFetch.sortDescriptors = [
            NSSortDescriptor(key: "question", ascending: true)
        ]
        let randomPrompt: ReflectionPrompt
        
        if paidAppStatus != .proSubscription {
            promptFetch.predicate = NSPredicate(format: "customYN == false")
            let allPrompts = (try? context.fetch(promptFetch)) ?? []
            let promptCount = allPrompts.count
            let randomIndex = Int.random(in: 0..<promptCount)
            randomPrompt = allPrompts[randomIndex]
        } else {
            let allPrompts = (try? context.fetch(promptFetch)) ?? []
            let promptCount = allPrompts.count
            let randomIndex = Int.random(in: 0..<promptCount)
            randomPrompt = allPrompts[randomIndex]
        }
        
        // Creating the response, assigning it to the current ActivityReflection
        // and saving the context
        dataController.createNewPromptResponse(
            using: randomPrompt,
            for: reflection
          )
    }//: giveRandomPrompt()
    
}//: STRUCT


// MARK: - PREVIEW
struct ActivityReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReflectionView(activity: .example, reflection: .example)
            
    }
}

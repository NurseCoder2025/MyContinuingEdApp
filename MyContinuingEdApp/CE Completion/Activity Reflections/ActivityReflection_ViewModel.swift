//
//  ActivityReflection_ViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/25/26.
//

import CoreData
import Foundation
import SwiftUI

extension ActivityReflectionView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        @ObservedObject var reflection: ActivityReflection
        let dataController: DataController
        
        var responseToDelete: ReflectionResponse? = nil
        
        @Published var fileErrorTitle: String = "Deletion Error"
        @Published var fileErrorMessage: String = ""
        @Published var showFileErrorAlert: Bool = false
        
        // MARK: - COMPUTED PROPERTIES
        
        var assignedActivityTitle: String {
            if let completedCe = reflection.ceToReflectUpon {
                return completedCe.ceTitle
            } else {
                return "Unknown Activity"
            }//: IF LET
        }//: assignedActivityTitle
        
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
        
        // MARK: - METHODS
        
        /// Method part of ActivityReflection's view model that returns a randomized reflection response object
        /// for a user who wants it.  This method is called when the "Random Prompt" button is tapped in the
        /// menu in ActivityReflectionView > Learning Prompts section.
        /// - Returns: random ReflectionResponse object
        ///
        /// - Note: The randomization is used to assign a random prompt (if the user is a subscriber,
        /// then any custom prompts will be included) to the creation of a new ReflectionResponse object,
        /// which has a ReflectionPrompt object as one of its relationship properties.
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
            _ = dataController.createNewReflectionResponse(
                using: randomPrompt,
                for: reflection
              )
        }//: giveRandomPrompt()
        
        func createInitialResponseWithoutPrompt() -> ReflectionResponse{
            let newResponse = dataController.createNewReflectionResponse(for: reflection)
            return newResponse
        }//: createInitialResponseWithoutPrompt()
        
        func deleteSelectedResponse() {
            if let selectedResponse = responseToDelete {
                if selectedResponse.hasAudioReflection {
                    Task {@MainActor in
                        do {
                            // TODO: Replace audioBrain code here
                            selectedResponse.hasAudioReflection = false
                            selectedResponse.audioLength = 0.0
                        } catch {
                            NSLog(">>> Error while trying to delete the audio reflection data associated with the selected prompt: \(selectedResponse.getAssignedPrompt())")
                            // TODO: Update the NSLog to hold specific error message
                            NSLog(">>> Specific error: ")
                            fileErrorMessage = "There was an error while trying to delete the audio reflection data associated with the selected prompt."
                            showFileErrorAlert = true
                            return
                        }//: DO-CATCH
                    }//: TASK
                    
                    // Once the audio data and its corresponding coordinator object have
                    // been deleted, then remove the CoreData object
                    if selectedResponse.hasAudioReflection == false {
                        dataController.delete(selectedResponse)
                        dataController.save()
                        responseToDelete = nil
                    }//: IF (hasAudioReflection == false)
                } else if selectedResponse.hasAudioReflection {
                    // Code for handling the unlikely situation where the audioBrain
                    // environment key has a nil value (is supposed to be set in the main
                    // app struct)
                    NSLog(">>> Error while trying to delete a ReflectionResponse that is marked as having audio data due to a nil audioBrain environment key value.")
                    fileErrorMessage = "Unable to delete the reflection response due to a technical issue with setting up a needed component. Restart the app and/or device and try again."
                    showFileErrorAlert = true
                } else {
                    dataController.delete(selectedResponse)
                    dataController.save()
                    responseToDelete = nil
                }//: IF ELSE (hasAudioReflection)
            }//: IF LET (selectedResponse)
        }//: deleteSelectedResponse()
        
        // MARK: - INIT
        
        init(dataController: DataController, reflection: ActivityReflection) {
            self.dataController = dataController
            self.reflection = reflection
        }//: INIT
        
    }//: CLASS
    
}//: EXTENSION

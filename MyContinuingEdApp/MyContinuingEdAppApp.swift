//
//  MyContinuingEdAppApp.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import SwiftUI
import CoreData
import CoreSpotlight

@main
struct MyContinuingEdAppApp: App {
    @StateObject var dataController: DataController = DataController()
    @State var certificateBrain: CertificateBrain?
    @State var spotlightCentral: SpotlightCentral?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if dataController.showOnboardingScreen {
                OnboardingView()
                    .environmentObject(dataController)
            } else  {
                NavigationSplitView {
                    SidebarView(dataController: dataController)
                } content: {
                    ContentView(dataController: dataController)
                } detail: {
                    DetailView()
                }//: NAV SPLIT VIEw
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environment(\.spotlightCentral, spotlightCentral)
                .environment(\.certificateBrain, certificateBrain)
                // MARK: - ON CHANGE OF
                // Saves changes if the app is moved to the background by the user
                .onChange(of: scenePhase) { phase in
                    if phase != .active {
                        dataController.save()
                    }
                } //: ONCHANGE
                  // MARK: - ON APPEAR
                .onAppear {
                    if spotlightCentral == nil {
                        spotlightCentral = SpotlightCentral(dataController: dataController)
                    }//: IF (spotlightCentral)
                    
                    if certificateBrain == nil {
                        certificateBrain = CertificateBrain(dataController: dataController)
                    }//: IF (certificateBrain)
                }//: ON APPEAR
                
                // MARK: - SPOTLIGHT
                .onContinueUserActivity(CSSearchableItemActionType, perform: { action in
                    spotlightCentral?.loadSpotlightItem(action)
                }
                )//: ON CONTINUE USER ACTIVITY
            }//: IF ELSE
        } //: WINDOW GROUP
    } //: BODY
    
    
    // MARK: - INIT
    
}

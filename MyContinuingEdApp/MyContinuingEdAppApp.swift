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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var dataController: DataController = DataController()
    @State var spotlightCentral: SpotlightCentral?
    @AppStorage(String.onBoardingKey) private var showUserOnboarding: Bool = true
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if showUserOnboarding {
                OnboardingView()
                    .environmentObject(dataController)
                    .onAppear {
                        showUserOnboarding = dataController.showOnboardingScreen
                    }//: ON APPEAR
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

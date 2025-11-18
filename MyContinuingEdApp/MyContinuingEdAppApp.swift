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
    @StateObject var appSettings: CeAppSettings = CeAppSettings()
    @State var spotlightCentral: SpotlightCentral?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView(dataController: dataController)
            } content: {
                ContentView(dataController: dataController)
            } detail: {
                DetailView()
            }
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
            .environmentObject(appSettings)
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
                }
            }//: ON APPEAR
            
            // MARK: - SPOTLIGHT
            .onContinueUserActivity(CSSearchableItemActionType, perform: { action in
                    spotlightCentral?.loadSpotlightItem(action)
                }
            )//: ON CONTINUE USER ACTIVITY
            
        } //: WINDOW GROUP
    } //: BODY
    
    
    // MARK: - INIT
    
}

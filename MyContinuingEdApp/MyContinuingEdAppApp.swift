//
//  MyContinuingEdAppApp.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/8/25.
//

import SwiftUI
import CoreData

@main
struct MyContinuingEdAppApp: App {
    @StateObject var dataController = DataController()
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
            // Saves changes if the app is moved to the background by the user
            .onChange(of: scenePhase) { phase in
                if phase != .active {
                    dataController.save()
                }
            } //: ONCHANGE
            
        } //: WINDOW GROUP
    } //: BODY
}

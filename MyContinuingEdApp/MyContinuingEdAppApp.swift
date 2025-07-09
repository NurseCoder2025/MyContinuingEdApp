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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
            
        }
    }
}

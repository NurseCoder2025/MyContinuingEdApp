//
//  CredentialDAISectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/4/25.
//

import CoreData
import SwiftUI

struct CredentialDAISectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var credential: Credential
    
    // MARK: - COMPUTED PROPERTIES
    var allDAIs: [DisciplinaryActionItem] {
        // Create empty array to hold results
        var actions: [DisciplinaryActionItem] = []
            
        // Create fetch request and sort by action name
            let request = DisciplinaryActionItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionName, ascending: true)]
            request.predicate = NSPredicate(format: "credential == %@", credential)
            actions = (try? dataController.container.viewContext.fetch(request)) ?? []
        
        return actions
    }//: allDAIs
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section("Disciplinary Actions") {
                List {
                    NavigationLink {
                        DisciplinaryActionListSheet(
                            dataController: dataController,
                            credential: credential
                        )
                    } label: {
                        HStack {
                            Text("Disciplinary Actions:")
                        }//: HSTACK
                        .badge(allDAIs.count)
                        .accessibilityElement()
                        .accessibilityLabel("Disciplinary actions taken against this credential")
                        .accessibilityHint("^[\(allDAIs.count) action taken](inflect: true)")
                    }//: NAV LINK
                   
                }//: LIST
            }//: SECTION
        }//: GROUP
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    CredentialDAISectionView(credential: .example)
}

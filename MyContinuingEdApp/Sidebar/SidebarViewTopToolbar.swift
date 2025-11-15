//
//  SidebarViewToolbar.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/15/25.
//


// Purpose: To encapsulate functionality for showing the awards and credential management sheets from the parent
// view (SidebarView)


import SwiftUI

struct SidebarViewTopToolbar: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @State private var showAwardsSheet: Bool = false
    @State private var showCredentialManagementSheet: Bool = false
    @State private var showChartsAndStatsSheet: Bool = false
    
    // MARK: - BODY
    var body: some View {
        
        // MARK: - Awards button
        Button {
            showAwardsSheet.toggle()
        } label: {
            Label("Show awards", systemImage: "rosette")
        }//: BUTTON
        .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
        
        // MARK: - Credential Management Sheet
        Button {
            // Action
            showCredentialManagementSheet = true
        } label: {
            Label(
                "Manage Credentials",
                systemImage: "person.text.rectangle.fill"
            )
        }//: BUTTON
        .sheet(isPresented: $showCredentialManagementSheet) {
            CredentialManagementSheet(dataController: dataController)
        }//: SHEET
        // MARK: - Charts Sheet
        Button {
            showChartsAndStatsSheet = true
        } label: {
            Label("Charts and Stats", image: "chart.bar.xaxis")
        }//: BUTTON
        .sheet(isPresented: $showChartsAndStatsSheet) {
            MasterChartsSheet()
        }
        
        
    #if DEBUG
        Button {
            dataController.deleteAll()
            dataController.createSampleData()
        } label: {
            Label("Add Samples", systemImage: "flame")
        }
    #endif
        
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    SidebarViewTopToolbar()
}

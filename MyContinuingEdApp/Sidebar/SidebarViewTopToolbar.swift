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
            HStack {
                // MARK: - Awards button
                Button {
                    showAwardsSheet.toggle()
                } label: {
                    Label("Show awards", systemImage: "rosette")
                }//: BUTTON
                
                
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
                
                 // MARK: - Charts Sheet
                Button {
                    showChartsAndStatsSheet = true
                } label: {
                    Label("Charts and Stats", systemImage: "chart.bar.xaxis")
                }//: BUTTON
               
                
#if DEBUG
                Button {
                    dataController.deleteAll()
                    dataController.createSampleData()
                } label: {
                    Label("Add Samples", systemImage: "flame")
                }
#endif
                
            }//: HSTACK
             // MARK: - SHEETS
             .sheet(isPresented: $showChartsAndStatsSheet) {
                 MasterChartsSheet()
             }
             
             .sheet(isPresented: $showCredentialManagementSheet) {
                 CredentialManagementSheet(dataController: dataController)
             }//: SHEET
             
             .sheet(isPresented: $showAwardsSheet, content: AwardsView.init)
            
    }//: BODY
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    SidebarViewTopToolbar()
}

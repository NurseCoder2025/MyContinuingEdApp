//
//  CeDesignationSelectionSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/26/25.
//

import CoreData
import SwiftUI

struct CeDesignationSelectionSheet: View {
    // MARK: - PROPERTIES
    // For sheet dismissal
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // Properties for editing the CeDesignation for the passed-in activity
    @State private var showAddEdit: Bool = false
    @State private var selectedByUser: Bool = false
    @State private var selectedDesignation: CeDesignation?
    
    // Alert properties
    @State private var showDeleteWarning: Bool = false
    
    // MARK: - Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.designationAbbreviation)]) var allDesignations: FetchedResults<CeDesignation>
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                Text("A variety of designations have been pre-loaded to cover the more common professions, but you can add your own as needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                // Designation List
                List {
                    ForEach(allDesignations) { designation in
                        Button {
                            selectedDesignation = designation
                            activity.designation = designation
                        } label: {
                            DesignationBoxView(
                                designation: designation,
                                selectedYN: selectedDesignation == designation
                            )
                            .accessibilityElement()
                            .accessibilityLabel("\(designation.ceDesignationName)")
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            // MARK: Editing designation button
                            Button {
                                selectedDesignation = designation
                                showAddEdit = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            // MARK: Deleting designation button
                            Button(role: .destructive) {
                                selectedDesignation = designation
                                showDeleteWarning = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            
                        } //: SWIPE ACTIONS
                    } //: LOOP
                    
                }//: List
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
                .background(Color.clear)
                .padding(.leading, 15)
                
                Spacer()
                
                
            }//: VSTACK
            .navigationTitle("CE Designation")
            // MARK: - TOOLBAR
            .toolbar {
                // Add new designation button
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        selectedDesignation = nil
                        showAddEdit = true
                    } label: {
                        Label("Add Designation", systemImage: "plus")
                    }
                }//: TOOLBAR ITEM
                
                // Dismiss button
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }//: BUTTON
                }//: TOOLBAR ITEM
               
            }//: TOOLBAR
            
            // MARK: - ALERTS
            .alert(isPresented: $showDeleteWarning) {
                Alert(
                    title: Text("Confirm deletion"),
                    message: Text("Are you sure you wish to delete this designation? This cannot be undone."),
                    primaryButton: .default(Text("Delete")) {
                        if let desToBeDeleted = selectedDesignation {
                            dataController.delete(desToBeDeleted)
                        }
                    },
                    secondaryButton: .cancel() {
                        showDeleteWarning = false
                    }
                )//: ALERT
            } //: ALERT MODIFIER
            
        }//: NAV VIEW
       
        
        // MARK: - SHEETS
        .sheet(isPresented: $showAddEdit) {
            if let desToBeEdited = selectedDesignation {
                DesignationEditView(designation: desToBeEdited)
                    
            } else {
                DesignationEditView()
                   
            }
        }
        
        
    }//: BODY
}


// MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    let viewContext = controller.container.viewContext

    return CeDesignationSelectionSheet(activity: .example)
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(controller)
}

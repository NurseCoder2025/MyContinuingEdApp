//
//  DisciplinaryActionListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/16/25.
//


// Purpose: show all Disciplinary Action Items in a list for the user to edit and add as needed

import CoreData
import SwiftUI

struct DisciplinaryActionListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // For adding a new DAI (Disciplinary Action Item)
    @State private var addNewDAI: Bool = false
    
    // For editing an existing DAI
    @State private var daiTOEdit: DisciplinaryActionItem?
    
    // For deleting an existing DAI
    @State private var daiToDelete: DisciplinaryActionItem?
    
    // Showing the deletion alert
    @State private var showDeletionWarning: Bool = false
    
    // MARK: - CORE DATA FETCHES
    @FetchRequest(sortDescriptors: [SortDescriptor(\.actionStartDate), SortDescriptor(\.actionName)]) var allDAIs: FetchedResults<DisciplinaryActionItem>
    
    
    // MARK: - BODY
    var body: some View {
        // Creating a date formatter to show the action start date in mm/dd/yyyy format
        var tradDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter
        }
        
        NavigationView {
            if allDAIs.isEmpty {
                NoDAIsView()
            } else {
                List {
                    ForEach(allDAIs) {dai in
                        Group {
                            VStack {
                                HStack {
                                    Text(dai.daiActionName)
                                        .lineLimit(1)
                                    Text(tradDateFormatter.string(from: dai.daiActionStartDate))
                                }//: HSTACK
                                Text(dai.daiActionType)
                                    .italic()
                            }//: VSTACK
                        }//: GROUP
                        .swipeActions {
                            // Edit
                            Button {
                                daiTOEdit = dai
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            // Delete
                            Button(role: .destructive) {
                                daiToDelete = dai
                                showDeletionWarning = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }//: LOOP
                    
                }//: LIST
                .navigationTitle("Disciplinary Actions")
                // MARK: - TOOLBAR
                .toolbar {
                    // Dismissing the List sheet
                    Button {
                        dismiss()
                    } label: {
                        DismissButtonLabel()
                    }.applyDismissStyle()
                    
                    // Add new DAI
                    Button {
                        addNewDAI = true
                    } label: {
                        Label("Add Disciplinary Action", systemImage: "plus")
                    }
                }//: TOOLBAR
                
                // MARK: - SHEETS
                // For adding a new DAI item
                .sheet(isPresented: $addNewDAI) {
                    DisciplinaryActionItemSheet(disciplinaryAction: nil)
                }
                // For editing a DAI item
                .sheet(item: $daiTOEdit) {_ in
                    DisciplinaryActionItemSheet(disciplinaryAction: daiTOEdit)
                }
                
                // MARK: - ALERTS
                .alert("Delete Disciplinary Action", isPresented: $showDeletionWarning) {
                    Button("Delete", role: .destructive, action: {deleteDAI()})
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete this disciplinary action?  Once deleted it cannot be undone.")
                }
            }//: IF-ELSE
        }//: NAV VIEW
    }
    
    // MARK: - FUNCTIONS
    func deleteDAI() {
        if let selectedDAI = daiToDelete {
            dataController.delete(selectedDAI)
        }
        
        dataController.save()
    }
}

// MARK: - PREVIEW
#Preview {
    let controller = DataController(inMemory: true)
    DisciplinaryActionListSheet()
        .environmentObject(controller)
        .environment(\.managedObjectContext, controller.container.viewContext)
}

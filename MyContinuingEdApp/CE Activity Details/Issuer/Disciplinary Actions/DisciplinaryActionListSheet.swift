//
//  DisciplinaryActionListSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/16/25.
//


// Purpose: show all Disciplinary Action Items in a list for the user to edit and add as needed

// 10-14-25 update: Adding the credential property in order for disciplinary actions to be associated with a
// specific credential

import CoreData
import SwiftUI

struct DisciplinaryActionListSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    // Passing in a credential object for which all associated disciplinary actions will be assigned to
    @ObservedObject var credential: Credential
    
    // For adding a new DAI (Disciplinary Action Item)
    @State private var addNewDAI: Bool = false
    @State private var newDAI: DisciplinaryActionItem?
    
    // For editing an existing DAI
    @State private var daiTOEdit: DisciplinaryActionItem?
    
    // For deleting an existing DAI
    @State private var daiToDelete: DisciplinaryActionItem?
    
    // Showing the deletion alert
    @State private var showDeletionWarning: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    /// The allDAIs computed property returns an array of DisciplinaryActionItems that are associated with whichever credential was passed into the view.  If none
    /// are related, then an empty array will be returned.
    var allDAIs: [DisciplinaryActionItem] {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<DisciplinaryActionItem> = DisciplinaryActionItem.fetchRequest()
        request.predicate = NSPredicate(format: "credential == %@", credential)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionStartDate, ascending: true)]
        
        let fetchedDAIs: [DisciplinaryActionItem] = (try? context.fetch(request)) ?? []
        return fetchedDAIs
    }
    
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            if allDAIs.isEmpty {
                NoDAIsView(credential: credential, onAddDAI: {
                    newDAI = dataController.createNewDAI(for: credential)
                    addNewDAI = true
                })
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
                    // Add new DAI
                    Button {
                        newDAI = dataController.createNewDAI(for: credential)
                        addNewDAI = true
                    } label: {
                        Label("Add Disciplinary Action", systemImage: "plus")
                    }
                    
                }//: TOOLBAR
                // MARK: - SHEETS
                // For adding a new DAI item
                .sheet(isPresented: $addNewDAI) {
                    if let createdDAI = newDAI {
                        DisciplinaryActionItemSheet(disciplinaryAction: createdDAI)
                    }
                }//: SHEET
                // For editing a DAI item
                .sheet(item: $daiTOEdit) {_ in
                    if let selectedDAI = daiTOEdit {
                        DisciplinaryActionItemSheet(disciplinaryAction: selectedDAI)
                    }//: IF LET
                }//: SHEET
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
    DisciplinaryActionListSheet(credential: .example)
        .environmentObject(controller)
        .environment(\.managedObjectContext, controller.container.viewContext)
}

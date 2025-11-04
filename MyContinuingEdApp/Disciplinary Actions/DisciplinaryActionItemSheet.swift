//
//  DisciplinaryActionItemSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/15/25.
//

// 10-14-25 update: originally used an optional let property to hold a DisciplinaryActionItem but am changing to
// an @ObservableObject

import SwiftUI

// Purpose: For creating or editing DisciplinaryActionItems from within the DisciplinaryActionListSheet

struct DisciplinaryActionItemSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // Property to hold an existing object that the user wishes to edit
    @ObservedObject var disciplinaryAction: DisciplinaryActionItem
    
    // DisciplinaryActionItem properties for UI controls
    @State private var name: String = ""
    @State private var descript: String = ""
    
    // using the DisciplineType enum value as a String
    @State private var type: String = DisciplineType.warning.rawValue.capitalized
    
    // Properties related to the start and (possibly) end date of the
    // disciplinary action
    @State private var startDate: Date = Date.now
    @State private var endDate: Date = .probationaryEndDate
    
    // Properties related to any required continuing education hours
    @State private var requiredCEHours: Double = 15.00
    @State private var ceDeadlineDate: Date = Date.now.addingTimeInterval(60*60*24*30)
    
    // Properties related to fines imposed
    @State private var fineAmount: Double = 0.00
    @State private var fineDeadline: Date = Date.now.addingTimeInterval(60*60*24*30)
    
    // Properties related to community service hours imposed
    @State private var communityServiceHours: Double = 0.00
    @State private var communityServiceDeadline: Date = Date.now.addingTimeInterval(60*60*24*30)
    
    @State private var selectedActions: [DisciplineAction] = []
    @State private var isTempOnly: Bool = true
    @State private var resolutionNotes: String = ""
    
    // Properties related to any appeals made for this disciplinary action
    @State private var isAppealed: Bool = false
    @State private var appealedOnDate: Date = Date.now
    @State private var appealNotes: String = ""
    
    // Properties for sheet header shape
    let title: String = "Disciplinary Action"
    let messageText: String  = """
    We hope this doesn't happen to you, but if it does then document
    whatever actions your credential's governing body has taken.
    If the action taken, such as a probationary period, has an end date,
    be sure to toggle the switch by 'Temporary?' to indicate that.
    """
    @State private var showHeaderShape: Bool = true
    
    // MARK: - BODY
    var body: some View {
        NavigationView {
            VStack {
                if showHeaderShape {
                    HeaderNoteView(titleText: title, messageText: messageText, dismissAction: {
                        showHeaderShape.toggle()
                    })
                }
                // MARK: FORM
                Form {
                    // MARK: - General Info Section
                    Section("General Information") {
                        TextField("Action Name", text: $name)
                        TextField("Description", text: $descript)
                        
                        // Date of disciplinary action
                        DatePicker("Action Date", selection: $startDate, displayedComponents: .date)
                        Toggle("Temporary action?", isOn: $isTempOnly)
                        if isTempOnly {
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        } else {
                            Text("PERMANENT ACTION")
                                .bold()
                                .foregroundStyle(.red)
                        }
                        
                    }//: General INFO SECTION
                    
                    // MARK: - ACTIONS Section
                    Section("Action(s)") {
                        // Type of action being taken (values from enum)
                        Picker("Type of Action", selection: $type) {
                            ForEach(DisciplineType.allCases, id: \.self) { disciplineType in
                                Text(disciplineType.rawValue.capitalized)
                            }//: LOOP
                        }//: PICKER
                        
                       // MARK: Actions Taken section
                        // Multi-selection for actions taken
                        Section("Actions Taken - Select All That Apply") {
                            MultipleSelectionGridView(actions: DisciplineAction.allCases, selectedActions: $selectedActions)
                        }//: SECTION (Actions TAKEN)
                        
                        TextField("Notes", text: $resolutionNotes)
                        
                    }//: SECTION (ACTIONS)
                    
                    
                    // MARK: Fines Section
                    if selectedActions.contains(.fines) {
                        Section("Fine Details") {
                            HStack {
                                Text("Fine Amount: ")
                                TextField(
                                    "Fine Amount",
                                    value: $fineAmount,
                                    formatter: currencyFormatter
                                )
                                    .keyboardType(.decimalPad)
                                    
                            }//: HSTACK
                            
                            DatePicker(
                                "Due By:",
                                selection: $fineDeadline,
                                displayedComponents: .date
                            )
                        }//: SECTION (Fines)
                    }//: IF (FINES)
                    
                    // MARK: Remedial CE Section
                    if selectedActions.contains(.continuingEd) {
                        // Only show this section if remedial CE is one of the selected actions
                        
                        Section("Remedial Continuing Education") {
                            // Any required CE hours
                            HStack {
                                Text("Required CEs: ")
                                TextField(
                                    "Required CE Hours",
                                    value: $requiredCEHours,
                                    formatter: ceHourFormatter
                                )
                                .keyboardType(.decimalPad)
                            }//: HSTACK
                            
                            // ONLY show the deadline date picker IF remedial
                            // CE hours are required (> 0)
                            if requiredCEHours > 0 {
                                DatePicker(
                                    "Deadline:",
                                    selection: $ceDeadlineDate,
                                    displayedComponents: .date
                                )
                            }//: IF
                            
                        }//: CE SECTION
                    }//: IF (REMEDIAL CE)
                    
                    // MARK: Community Service Section
                    if selectedActions.contains(.community) {
                        // Only show this section if community service is one of the selected actions
                        
                        Section("Community Service Details") {
                            // Any required community service hours
                            HStack {
                                Text("Required Hours: ")
                                TextField(
                                    "Required Community Service Hours",
                                    value: $communityServiceHours,
                                    formatter: hoursFormatter
                                )
                                .keyboardType(.decimalPad)
                            }//: HSTACK
                            
                            // ONLY show the deadline date picker IF community
                            // service hours are required (> 0)
                            if communityServiceHours > 0 {
                                DatePicker(
                                    "Deadline:",
                                    selection: $communityServiceDeadline,
                                    displayedComponents: .date
                                )
                            }//: IF
                            
                        }//: COMMUNITY SERVICE SECTION
                    }//: IF
                    
                    
                    // MARK: Appeal Section
                    Section("Appeal") {
                        Toggle("Appealed Decision", isOn: $isAppealed)
                        if isAppealed {
                            DatePicker("Date Appealed", selection: $appealedOnDate, displayedComponents: .date)
                            TextField("Notes", text: $appealNotes)
                        }
                        
                    }//: APPEAL SECTION
                    
                }//: FORM
                
                // MARK: SAVE Button
                Button {
                    mapANDSave()
                    dismiss()
                } label: {
                    Label("Save", systemImage: "internaldrive.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                
            }//: VSTACK
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if disciplinaryAction.actionName == "New Action" {
                            dataController.delete(disciplinaryAction)
                        }//: IF
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }
                }//: TOOLBAR ITEM
            }//: TOOLBAR
            
            // MARK: - AUTO SAVE
            .onReceive(disciplinaryAction.objectWillChange) { _ in
                dataController.queueSave()
            }//: ON RECEIVE
            .onSubmit {mapANDSave()}
           
            
            // MARK: - ON APPEAR
            .onAppear {
                // Initialize fields from the disciplinaryAction object if it exists
                name = disciplinaryAction.daiActionName
                descript = disciplinaryAction.daiActionDescription
                type = disciplinaryAction.daiActionType
                startDate = disciplinaryAction.actionStartDate ?? Date.now
                endDate = disciplinaryAction.actionEndDate ?? .probationaryEndDate
                selectedActions = disciplinaryAction.actionsTaken
                requiredCEHours = disciplinaryAction.disciplinaryCEHours
                isTempOnly = disciplinaryAction.temporaryOnly
                resolutionNotes = disciplinaryAction.daiResolutionActions
                isAppealed = disciplinaryAction.appealedActionYN
                appealedOnDate = disciplinaryAction.appealDate ?? Date.now
                appealNotes = disciplinaryAction.daiAppealNotes
                ceDeadlineDate = disciplinaryAction.daiCEDeadlineDate
                fineAmount = disciplinaryAction.fineAmount
                fineDeadline = disciplinaryAction.daiFinesDueDate
                communityServiceHours = disciplinaryAction.commServiceHours
                communityServiceDeadline = disciplinaryAction.daiCommunityServiceDeadline
                
            }//: ON APPEAR
            
        }//: NAV VIEW
    }
    // MARK: - FUNCTIONS
    
    /// Function for saving any input that the user has made in the controls for either an existing or new disciplinary action item (which is created when
    ///  the disciplinaryAction property is nil).  After mapping all of the properties the dataController's save method is then called to save the object.
    func mapANDSave() {
            disciplinaryAction.actionName = name
            disciplinaryAction.actionDescription = descript
            disciplinaryAction.actionType = type
            disciplinaryAction.actionStartDate = startDate
            disciplinaryAction.actionEndDate = endDate
            disciplinaryAction.disciplinaryCEHours = requiredCEHours
            disciplinaryAction.actionsTaken = selectedActions
            disciplinaryAction.temporaryOnly = isTempOnly
            disciplinaryAction.resolutionActions = resolutionNotes
            disciplinaryAction.appealedActionYN = isAppealed
            disciplinaryAction.appealDate = appealedOnDate
            disciplinaryAction.appealNotes = appealNotes
            disciplinaryAction.ceDeadline = ceDeadlineDate
            disciplinaryAction.fineAmount = fineAmount
            disciplinaryAction.fineDeadline = fineDeadline
            disciplinaryAction.commServiceHours = communityServiceHours
            disciplinaryAction.commServiceDeadline = communityServiceDeadline
            
        dataController.save()
        
    }//: MAP & SAVE
    
}



// MARK: - PREVIEW
#Preview {
    DisciplinaryActionItemSheet(disciplinaryAction: .example)
}

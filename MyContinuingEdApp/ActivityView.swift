//
//  ActivityView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/18/25.
//

// Purpose: For the creation and editing of Continuing Education (CE) activity objects.

import CoreData
import SwiftUI
import PhotosUI
import PDFKit


struct ActivityView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // Properties related to changes with the CE certificate
    @State private var showCertificateChangeAlert: Bool = false
    @State private var certificateToConfirm: CertificateDataWrapper?
    @State private var previousCertificate: Data?
    @State private var okToShowAlert: Bool = true
    
    // Properties related to deleting the saved certificate
    @State private var showDeleteCertificateWarning: Bool = false
    
    // Property for the selecting/changing the CE designation
    @State private var showCeDesignationSheet: Bool = false
    
    // Property for changing the activity type
    @State private var selectedActivityType: ActivityType?
    
    // Property for showing the Activity-CredentialSelectionSheet
    @State private var showACSelectionSheet: Bool = false
    
    // Property for showing the SpecialCECatAssignmentManagementSheet
    @State private var showSpecialCECatAssignmentSheet: Bool = false
    
    // Properties for the Credential selection popover
    @State private var showCredentialSelectionPopover: Bool = false
    @State private var selectedCredential: Credential?

    
    // MARK: - COMPUTED PROPERTIES
    
    // Property that returns a joined String of all Credential names assigned to an activity
    var assignedCredentials: String {
        let sortedCreds = activity.activityCredentials.sorted()
        let credString = sortedCreds.map {$0.credentialName}.joined(separator: ",")
        
        return credString
    }
    
    
    // MARK: - Core Data Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.designationAbbreviation)]) var allDesignations: FetchedResults<CeDesignation>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.typeName)]) var allActivityTypes: FetchedResults<ActivityType>
    
    // MARK: - BODY
    var body: some View {
        // formatting contact hours value to 2 decimal places for use in textfield
        let hoursFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        // creating a formatter for currency values to be used in another textfield
        let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            
            return formatter
        }()
        
        Form {
            // MARK: - HEADER section
            Section {
                VStack(alignment: .leading) {
                    // Activity Title
                    TextField(
                        "Title:",
                        text: $activity.ceTitle,
                        prompt: Text("Enter the activity name here"),
                        axis: .vertical
                    )
                        .font(.title)
                    
                    // Credential(s) to which activity is assigned to
                    if activity.activityCredentials.isNotEmpty {
                        Text("Assigned Credential(s): \(assignedCredentials)")
                    }
                    
                    Button {
                        showACSelectionSheet = true
                    } label: {
                        if activity.activityCredentials.isEmpty {
                            Label("Assign Credential", systemImage: "wallet.pass.fill")
                        } else {
                            Label("Manage Credential Assignments", systemImage: "list.bullet.clipboard.fill")
                        }
                    }
                    
                    
                    
                    // Modified Date
                    Text("**Modified:** \(activity.ceActivityModifiedDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)
                    
                    // Expiration status of activity
                    Text("**Expiration Status:** \(activity.expirationStatus.rawValue)")
                        .foregroundStyle(.secondary)
                } //: VSTACK (title and modification date)
                
                // User's rating of the activity
                Picker("My Rating:", selection: $activity.evalRating) {
                    Text(ActivityRating.terrible.rawValue).tag(Int16(0))
                    Text(ActivityRating.poor.rawValue).tag(Int16(1))
                    Text(ActivityRating.soSo.rawValue).tag(Int16(2))
                    Text(ActivityRating.interesting.rawValue).tag(Int16(3))
                    Text(ActivityRating.lovedIt.rawValue).tag(Int16(4))
                }
                // MARK: Tag Menu
                Menu {
                    // Selected tags
                    ForEach(activity.activityTags) { tag in
                        Button {
                            // Tapping button will remove tag for the specific activity and into the "missing tags" set
                            activity.removeFromTags(tag)
                        } label: {
                            Label(tag.tagTagName, systemImage: "checkmark")
                        } //: Button + Label
                        
                    }//: LOOP
                    
                    
                    // Unselected tags
                    let remainingTags = dataController.missingTags(from: activity)
                    
                    if remainingTags.isNotEmpty {
                        Divider()
                        
                        Section("Add Tags") {
                            ForEach(remainingTags) { tag in
                                Button {
                                    activity.addToTags(tag)
                                } label: {
                                    Text(tag.tagTagName)
                                } //: BUTTON + label
                                
                            } //: LOOP
                            
                        } //: SECTION
                    } //: IF Statement
                    
                    
                } label: {
                    Text(activity.allActivityTagString)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil, value: activity.allActivityTagString)
                } //: MENU + Label
                
            } //: SECTION - Header
                // MARK: - Description & Expiration
                Section("Description & Activity Expiration") {
                    TextField("Description:", text: $activity.ceDescription, prompt: Text("Enter a description of the activity"), axis: .vertical)
                        .keyboardType(.default)
                    
                    Toggle("Expires?", isOn: $activity.activityExpires)
                    
                    if activity.activityExpires {
                        DatePicker("Expires On", selection: Binding(
                            get: { activity.expirationDate ?? Date.now },
                            set: { activity.expirationDate = $0 }),
                            displayedComponents: [.date])
                        
                        
                            .onChange(of: activity.expirationDate) { _ in
                                updateActivityStatus(status: activity.expirationStatus)
                            } //: ON CHANGE
                        
                    } //: IF expires...
                    
                } //: Description Subsection
                
            // MARK: - Hours & Cost
                Section("CE Awarded & Cost") {
                        HStack {
                            Text("CE Earned:")
                                .bold()
                                .padding(.trailing, 5)
                            TextField("Earned CE:", value: $activity.ceAwarded, formatter: hoursFormatter , prompt: Text("amount of CE awarded"))
                                .keyboardType(.decimalPad)
                            
                            Picker("", selection: $activity.hoursOrUnits){
                                Text("hours").tag(Int16(1))
                                Text("units").tag(Int16(2))
                            }//: PICKER
                            .labelsHidden()
                    
                        } //: HSTACK
                
                        
                        
                        HStack {
                            Text("Cost:")
                                .bold()
                                .padding(.trailing, 5)
                            TextField("Activity Cost:", value: $activity.cost, formatter: currencyFormatter, prompt: Text("Cost/Fees"))
                                .keyboardType(.decimalPad)
                                
                        } //: HSTACK
                    
                } //: Contact Hours & Cost subsection
            
            // MARK: - CE DETAILS
            // MARK: Designation
            Section("CE Details") {
                Button {
                    showCeDesignationSheet = true
                } label: {
                    HStack {
                        Text("Designated as:")
                        if let des = activity.designation {
                            Text(des.ceDesignationAbbrev)
                                .lineLimit(1)
                        } else {
                            Text("Select")
                        }
                    }//: HSTACK
                } //: BUTTON
                
                // MARK: Special Category
                VStack {
                    Text("Special CE Category:")
                        .bold()
                    Text("NOTE: If the activity certificate indicates that the hours/units are for a specific kind of continuing education requirement by the governing body, such as law or ethics, indicate that here.")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                    
                    Button {
                        showSpecialCECatAssignmentSheet = true
                    } label: {
                        HStack {
                            Text("Category:")
                            if let assignedCat = activity.specialCat {
                                Text(assignedCat.specialName)
                                    .lineLimit(1)
                            } else {
                                Text("Select Category (if applicable)")
                            }
                        }//: HSTACK
                    }
                    
                } //: VSTACK
                
                
            }//: SECTION
            
            // MARK: - Activity Type
            
            Section("Activity Type") {
                Picker("Type:", selection: $selectedActivityType) {
                    ForEach(allActivityTypes) { type in
                        Text(type.activityTypeName)
                            .tag(type as ActivityType?)
                    }//: LOOP
                    
                }//: PICKER
                .onChange(of: selectedActivityType) { newType in
                    activity.type = newType
                }
                
            }//: SECTION
            
                // MARK: - Activity Format Selection
                Section("Activity Format") {
                    Picker("Format", selection: $activity.ceActivityFormat) {
                        ForEach(ActivityFormat.allFormats) {format in
                            HStack {
                                Image(systemName: format.image)
                                Text(format.formatName)
                            }//: HSTACK
                            .tag(format.formatName)
                        }//: LOOP
                        
                    }//: PICKER
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }//: SECTION
                
         
            // MARK: - Activity Completion
            Section("Activity Completion") {
                Toggle("Activity Completed?", isOn: $activity.activityCompleted)
                if activity.activityCompleted {
                    DatePicker("Date Completed", selection: Binding(
                        get: {activity.dateCompleted ?? Date.now},
                        set: {activity.dateCompleted = $0}),
                    displayedComponents: [.date])
                    
                    if !activity.isDeleted, let reflection = activity.reflection {
                        NavigationLink {
                            ActivityReflectionView(activity: activity, reflection: reflection)
                        } label: {
                            Text("Activity reflections...")
                                .backgroundStyle(.yellow)
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        } //: NAV LINK
                        
                    }//: IF LET
                    
                } // IF activity completed...
            }// MARK: Activity Completion Section
            .onChange(of: activity.activityCompleted) { _ in
                if activity.reflection == nil {
                    let newReflection = dataController.createNewActivityReflection()
                    activity.reflection = newReflection
                } //: IF
            } //: ON CHANGE
            
            // MARK: - Certificate Image section
            if activity.activityCompleted {
                Section("Certificate Image") {
                    CertificatePickerView(
                        activity: activity,
                        certificateData: $activity.completionCertificate
                    )
                                        
                    if let data = activity.completionCertificate {
                        if isPDF(data) {
                            PDFKitView(data: data)
                                .frame(height: 300)
                        } else if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                        } else {
                            Text("Unsupported file format - must be either an image (.png, .jpg) or PDF only.")
                                .foregroundStyle(.secondary)
                        }
                    }//: IF LET (data)
                    
                   

                    // MARK: - Certificate Sharing
                    if let data = activity.completionCertificate {
                        CertificateShareView(activity: activity, certificateData: data)
                        
                        Button(role: .destructive) {
                            showDeleteCertificateWarning = true
                        } label: {
                            Text("Delete Certificate")
                        }
                    }
                    
                    
                }//: Certificate Section
                
            } //: IF activity completed
            
        } //: FORM
        // MARK: - ON APPEAR
        .onAppear {
            updateActivityStatus(status: activity.expirationStatus)
            previousCertificate = activity.completionCertificate
            selectedActivityType = activity.type
        } //: onAppear
        
        // MARK: - DISABLED
        .disabled(activity.isDeleted)
        
        // MARK: - ON RECEIVE
        .onReceive(activity.objectWillChange) { _ in
            dataController.queueSave()
        } //: onReceive
        
        // MARK: - ON CHANGE
        .onChange(of: activity.dateCompleted) { _ in
            dataController.assignActivitiesToRenewalPeriod()
        }
        .onChange(of: activity.completionCertificate) { newCertificate in
            // Prevent alert from appearing after user cancels a change
            if okToShowAlert == false {
                okToShowAlert = true
                previousCertificate = newCertificate
                return
            }
            
            // once a certificate has been saved, bring up an alert each
            // time the user wishes to change it...
            if let oldCert = previousCertificate,
               let newCert = newCertificate {
                       certificateToConfirm = CertificateDataWrapper(newData: newCert, oldData: oldCert)
                }
            
            previousCertificate = newCertificate
        }
        
        
        
        // MARK: - Changing Certificate Alert
        .alert(item: $certificateToConfirm) { wrapper in
            Alert(
                title: Text("Change Certificate?"),
                message: Text("Are you sure you wish to change the certificate associated with this activity?"),
                primaryButton: .default(Text("Confirm")) {
                    activity.completionCertificate = wrapper.newData
                   
                },
                secondaryButton: .cancel() {
                    okToShowAlert = false
                    if let data = wrapper.oldData {
                        activity.completionCertificate = data
                    }
                }
            )
        } //: Change ALERT
        
        // MARK: - Deleting Certificate Alert
        .alert("Delete Certificate", isPresented: $showDeleteCertificateWarning) {
            Button("DELETE", role: .destructive) {
                activity.completionCertificate = nil
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are about to delete the saved CE certificate. Are you sure?  This cannot be undone.")
        }
        
        // MARK: - SHEETS
        // CeDesgination selection (i.e. CME, legal CE, etc.)
        .sheet(isPresented: $showCeDesignationSheet) {
                CeDesignationSelectionSheet(activity: activity)
        }//: SHEET (CE Designation)
        
        // Credential(s) selection
        .sheet(isPresented: $showACSelectionSheet) {
            Activity_CredentialSelectionSheet(activity: activity)
        }//: SHEET (activity-credential selection)
        
        // CE Category selection
        .sheet(isPresented: $showSpecialCECatAssignmentSheet) {
            SpecialCECatsManagementSheet(activity: activity)
        }//: SHEET (SpecialCECatASsignmentManagementSheet)
        
        // MARK: - POPOVERS
        .popover(isPresented: $showCredentialSelectionPopover) {
            CredentialSelectionPopOver(
                activity: activity,
                selectedCredential: $selectedCredential,
                showCredentialSelectionPopover: $showCredentialSelectionPopover
            )
        }//: POPOVER
        
        
    }//: BODY
    
    
    // MARK: - Activity Specialty Methods
    /// The updateActivityStatus function exists to enable filtering functionality in the DataController. -->
    /// Adding this function in order to automatically assign the computed ExpirationType value from the CEActivity-Core
    /// DataHelper file (see bottom extension) to the direct property in Core Data.  Need to use this in order to
    /// properly filter activities by expiration status (type) in the DataController.
    func updateActivityStatus(status: ExpirationType) {
        activity.currentStatus = status.rawValue
    }
    
    func changeCertificateImage(certificate: Data) {
        
    }
    
}

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = DataController(inMemory: true)
        ActivityView(activity: .example)
            .environmentObject(controller)
            .environment(\.managedObjectContext, controller.container.viewContext)
    }
}



// MARK: - Certificate Data Wrapper struct
struct CertificateDataWrapper: Identifiable {
    let id = UUID()
    let newData: Data
    let oldData: Data?
}

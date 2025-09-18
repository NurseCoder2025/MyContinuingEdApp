//
//  LicenseSheet.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/28/25.
//

import CoreData
import SwiftUI

// The purpose of this view is to serve as the place where
// the user adds or edits credential objects

struct CredentialSheet: View {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    // License related properties
    let credential: Credential?
    
    // MARK: Credential properties
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var number: String = ""
    @State private var expiration: Date?
    @State private var renewalLength: Double = 24.0   // 2 year renewal period is common across many professions
    @State private var activeYN: Bool = true
    @State private var whyInactive: String = ""
    @State private var restrictedYN: Bool = false
    @State private var restrictionsDetails: String = ""
    
    // MARK: Issuer related properties
    @State private var issueDate: Date?
    @State private var credIssuer: Issuer?
    
    // Show list of Issuers property
    @State private var showIssuerListSheet: Bool = false

    // Properties for showing the renewal period sheet
    @State private var showRenewalPeriodView: Bool = false
    
    // Show the Credential-SpecialCatsSelectionSheet for selecting any specific special CE categories
    // that are required for the specific credential
    @State private var showCredSpecialCatSheet: Bool = false

    // Hold the newly created Credential for sheet presentation
    @State private var newCredential: Credential?
    
    // MARK: - Computed Properties
    
    // MARK: - Core Data Fetch Requests
    // This property will be used to determine the most recent (current) renewal
    // period for calculating the next expiration date of the credential
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodEnd, order: .reverse)]) var renewalsSorted: FetchedResults<RenewalPeriod>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.issuerName)]) var allIssuers: FetchedResults<Issuer>
    
    
    // MARK: - BODY
    var body: some View {
        // MARK: - BODY Properties
        /// Computed property to format any values where only a single decimal place is needed in a Text control.
        let singleDecimalFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            return formatter
        }()
        
        
        // MARK: - Main Nav VIEW
        NavigationView {
            Form {
                Section {
                    Text("Add your license or other credential on this screen.")
                }//: SECTION
                
                Section("Basic Info") {
                    // MARK: Credential name
                    TextField("Credential name", text: $name)
                    
                    // MARK: Credential type
                    Picker("Type", selection: $type) {
                        ForEach(Credential.allTypes, id:\.self) { type in
                            Text(type)
                        }//: LOOP
                    }//: PICKER
                   
                    // MARK: Credential number
                    TextField("Number", text: $number)
                    
                    // MARK: Credential issuer
                    // ONLY show the picker if at least 1 issuer has been entered
                    if allIssuers.isNotEmpty {
                        Picker("Issuer", selection: $credIssuer) {
                            ForEach(allIssuers) { issuer in
                                HStack {
                                    Text(issuer.issuerLabel)
                                    Text(issuer.country?.countryAbbrev ?? "No Country Selected")
                                        .foregroundStyle(.secondary)
                                }//: HSTACK
                                .tag(issuer)
                            }//: LOOP
                        } //: PICKER
                    }//: IF
                    
                    Button {
                        showIssuerListSheet = true
                    } label: {
                        Text(allIssuers.isEmpty ? "Add Issuer" : "Edit Issuers")
                    }
                    
                }//: SECTION
                
                // MARK: Special CE Categories for the Credential
                Section(
                    header: Text("Special CE Categories"),
                    footer: HStack {
                        Image(systemName: "info.circle")
                        Text("This section may or may not apply to your situation, depending on the credential and what CE requirements the licensing or governing body have in-place. Typically, a special CE category is a subject that the credential issuer wants so many hours/units of CE in as part of the renewal total. For example, it could be 2 hours of ethics as part of the 30 CE hour total.")
                    }//: HSTACK
                    
                ) {
                    Button {
                        if credential == nil {
                            newCredential = createNewCredential()
                            showCredSpecialCatSheet = true
                        } else {
                            showCredSpecialCatSheet = true
                        }
                    } label: {
                        specialCategoryButtonLabel()
                    }
                    
                    
                }//: SECTION
                
                // MARK: ACTIVE Y or N?
                Section {
                    Toggle("Credential Active?", isOn: $activeYN)
                    
                    // ONLY show the following fields if credential is inactive
                    if activeYN == false {
                        Text("Why Is the Credential Inactive?")
                        Picker("Inactive Reason", selection: $whyInactive) {
                            ForEach(InactiveReasons.defaultReasons) { reason in
                                Text(reason.reasonName).tag(reason.reasonName)
                            }//: LOOP
                        }//: PICKER
                        .pickerStyle(.wheel)
                        .frame(height:100)
                    }
                }//: SECTION
                
                
                Section("Issue & Renewal") {
                    // MARK: Issued Date
                    DatePicker("Issued On", selection: Binding(
                        get: {credential?.issueDate ?? Date.now},
                        set: {credential?.issueDate = $0}
                    ), displayedComponents: [.date])
                    
                    // MARK: Renewal Period Length
                    HStack(spacing: 4) {
                        Label("Renews every: ", systemImage: "calendar.badge.clock")
                        TextField("Renews in months", value: $renewalLength, formatter: singleDecimalFormatter )
                            .frame(maxWidth: 25)
                            .bold()
                            .foregroundStyle(.red)
                        Text("months")
                    }//: HSTACK
                    
                }//: SECTION
                
                // MARK: Next Expiration
                // Show the following section ONLY if editing an existing credential
                if credential != nil {
                    Section("Next Expiration"){
                        if renewalLength <= 0.0 {
                            Text("Please enter the number of months the credential is valid before it expires.")
                                .foregroundStyle(.secondary)
                        } else {
                            if renewalsSorted.isEmpty {
                                Text("Please add a renewal period in order to calculate the next expiration date for this credential.")
                                    .foregroundStyle(.secondary)
                                Button{
                                    showRenewalPeriodView = true
                                } label: {
                                    Label("Add Renewal", systemImage: "plus")
                                }
                            } else {
                                // If there is at least one value in the renewalsSorted fetch request, then
                                // calculate the next expiration date based on the first item in the array
                                let mostCurrentRenewal = renewalsSorted[0]
                                let minutesToRenew = mostCurrentRenewal.renewalPeriodEnd.timeIntervalSince(Date.now)
                                let daysToRenew = minutesToRenew / 86400
                                
                                // if the most recent renewal period happens to have an ending date prior to
                                // the current date (meaning no current renewal period has been entered yet) then
                                // alert the user and prompt him to add a new (current) period
                                if daysToRenew <= 0 {
                                    Text("The latest renewal period entered has ended./nPlease enter a new renewal period that includes today's date so that the time until the next expiration can be calculated.")
                                        .foregroundStyle(.secondary)
                                    Button {
                                        showRenewalPeriodView = true
                                    } label: {
                                        Text("Add new (current) renewal period")
                                    }
                                } else {
                                    VStack {
                                        Text(mostCurrentRenewal.renewalPeriodName)
                                        Text("\(NSNumber(value: daysToRenew), formatter: singleDecimalFormatter) days before the credential expires")
                                            .font(.title)
                                            .bold()
                                    }//: VSTACK
                                }
                            }//: INNER IF-ELSE
                            
                        } //: ELSE
                    }//: SECTION
                }//: IF not NIL
                
                // MARK: RESTRICTIONS
                Section("Credential Restrictions"){
                    Toggle("Any Restrictions?", isOn: $restrictedYN)
                    
                    // Details for any restrictions IF true
                    if restrictedYN {
                        TextField("Restriction details:", text: $restrictionsDetails)
                    }
                }//: SECTION
                
                // TODO: Add Disciplinary Action Hx section
                
                // MARK: SAVE Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            mapAndSave()
                            dismiss()
                        } label: {
                            Label("Save", systemImage: "internaldrive.fill")
                                .font(.title)
                        }
                        Spacer()
                    }//: HSTACK
                }//: SECTION
                
            }//: FORM
            // If the user changes the credential active switch to true from
            // false, reset the inactiveReason property to an empty string.
            .onChange(of: activeYN) { _ in
                if activeYN == true {
                    whyInactive = ""
                }
                
            }
            .navigationTitle(credential == nil ? "Add Credential" : "Credential Info")
            // Presenting the RenewalPeriodView if no RenewalPeriod objects exist at the time of the
            // object's creation
            
            // MARK: - TOOLBAR
            .toolbar {
                Button(action: {dismiss()}){
                    DismissButtonLabel()
                }.applyDismissStyle()
            }
            // MARK: - SHEETS
            .sheet(isPresented: $showRenewalPeriodView) {
                RenewalPeriodView(renewalPeriod: nil)
            }
            .sheet(isPresented: $showIssuerListSheet) {
                IssuerListSheet()
            }
            .sheet(isPresented: $showCredSpecialCatSheet) {
                if let cred = credential ?? newCredential {
                    SpecialCECatAssignmentManagementSheet(credential: cred)
                }
            }

        }//: NAV VIEW
    }//: BODY
    
    // MARK: - METHODS
    /// Method for assigning the values of each input field with the corresponding property in a Credential object.
    /// - Parameter cred: Credential object to be passed in
    func mapCredProperties(for cred: Credential) {
        cred.name = name
        cred.credentialType = type
        cred.credentialNumber = number
        cred.issueDate = issueDate
        cred.renewalPeriodLength = renewalLength
        cred.isActive = activeYN
        cred.isRestricted = restrictedYN
        cred.restrictions = restrictionsDetails
        cred.inactiveReason = whyInactive
        
        // If an issuer has been selected
        if let selectedIssuer = credIssuer {
            cred.issuer = selectedIssuer
        }
    }
    
    func mapAndSave() {
        // IF an existing Credential is being edited
        if let existingCred = credential {
            mapCredProperties(for: existingCred)
            
            dataController.save()
        } else {
            let context = dataController.container.viewContext
            let newCredential = Credential(context: context)
            
            mapCredProperties(for: newCredential)
            
            dataController.save()
            
        }
    }//: MAP & SAVE
    
    /// This function is intended to save a newly created Credential and then pass the object to the
    ///  "Credential\_SpecialCatsSelectionSheet" so the user can then assign whatever special CE categories are desired
    ///   to the newly created object.
    func createNewCredential() -> Credential? {
        let context = dataController.container.viewContext
        let newCredential = Credential(context: context)
        mapCredProperties(for: newCredential)
        dataController.save()
        return newCredential
    }
    
    /// Creates a label for the button that controls whether the Credential-SpecialCatSelectionSheet is shown. Depending on whether a credential
    ///  object was passed in (is being edited) or if a new one is being made, the wording will reflect the appropriate situation.
    /// - Returns: a Lable object with different title text and system image, depending on whether the user is making a new credential or
    ///      is editing an existing one that has special categories already assigned to it.
    func specialCategoryButtonLabel() -> some View {
        let labelDetails: Label<Text, Image>
        if let existingCred = credential, existingCred.assignedSpecialCeCategories.isNotEmpty {
            labelDetails = Label("Manage Special CE Categories", systemImage: "folder.badge.gear")
        } else {
           labelDetails = Label("Add Special CE Category", systemImage: "plus")
        }
        
        return labelDetails
    }
    
    
}

 // MARK: - PREVIEW
#Preview {
    CredentialSheet(credential: .example)
}

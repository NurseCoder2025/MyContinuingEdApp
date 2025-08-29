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
    var credential: Credential?
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var number: String = ""
    @State private var issuer: String = ""
    @State private var issueDate: Date?
    @State private var expiration: Date?
    @State private var renewalLength: Double = 0.0
    
    // Properties for showing the renewal period sheet
    @State private var showRenewalPeriodView: Bool = false
    
    // MARK: - Core Data Fetch Requests
    // This property will be used to determine the most recent (current) renewal
    // period for calculating the next expiration date of the credential
    @FetchRequest(sortDescriptors: [SortDescriptor(\.periodEnd, order: .reverse)]) var renewalsSorted: FetchedResults<RenewalPeriod>
    
    // MARK: - BODY
    var body: some View {
        // MARK: - BODY Properties
        let monthsFormatter: NumberFormatter = {
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
                    TextField("Issuer", text: $issuer)
                    
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
                        TextField("Renews in months", value: $renewalLength, formatter: monthsFormatter )
                            .frame(maxWidth: 25)
                            .bold()
                            .foregroundStyle(.red)
                        Text("months")
                    }//: HSTACK
                    
                }//: SECTION
                
                Section("Next Expiration"){
                    if renewalLength == 0 {
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
                        }//: INNER IF
                        
                    } //: ELSE
                }//: SECTION
                
                
            }//: FORM
            .navigationTitle(credential == nil ? "Add Credential" : "Credential Info")
            .sheet(isPresented: $showRenewalPeriodView) {
               RenewalPeriodView(dataController: DataController())
            }

        }//: NAV VIEW
    }//: BODY
}

 // MARK: - PREVIEW
#Preview {
    CredentialSheet(credential: .example)
}

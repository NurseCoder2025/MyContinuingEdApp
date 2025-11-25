//
//  BasicCredentialInfoView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: To display the UI controls for the user to enter basic information (ex. name,
// credential type, number, etc.) for a given credential object

// 10-13-25 update: Changed from having an optional Credential property to a non-optional

import CoreData
import SwiftUI

struct BasicCredentialInfoView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var settings: CeAppSettings
    @ObservedObject var credential: Credential
        
    // Property for bringing up the Issuer List sheet
    @State private var showIssuerListSheet: Bool = false
    
    @State private var showSpecialCECatsManagementSheet: Bool = false
    
    @State private var showCEMeasurementHelpAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        settings.settings.appPurchaseStatus
    }
    
    // MARK: - BODY
    var body: some View {
        Group {
            Section {
                Text("Add your license or other credential on this screen.")
            }//: SECTION
            
            Section("Basic Info") {
                // MARK: Credential name
                TextField("Credential name", text: $credential.credentialName)
                    .submitLabel(.done)
                    .onSubmit {
                        dismissKeyboard()
                    }
                
                // MARK: Credential type
                Picker("Type", selection: $credential.credentialCreType) {
                    ForEach(CredentialType.pickerChoices, id: \.self) { type in
                        Text(type.displaySingularName).tag(type.rawValue)
                    }//: LOOP
                }//: PICKER
                
                // MARK: Credential number
                TextField("Number", text: $credential.credentialCreNumber)
                    
                
                // MARK: Credential issuer
                Button {
                    showIssuerListSheet = true
                } label: {
                    HStack {
                        Text("Issuer: ")
                        if let selectedIssuer = credential.issuer {
                            Text(selectedIssuer.issuerIssuerName)
                                .lineLimit(1)
                        } else {
                            Text("Select")
                        }
                    }//: HSTACK
                }
                
            }//: SECTION
            
            // MARK: Credential Settings
            Section("Credential Settings") {
                Text("Set default values for the credential in this section.")
                Group {
                    VStack(alignment: .leading) {
                        Text("CEs Earned As")
                            .bold()
                        HStack {
                            Picker("Default CE Units", selection: $credential.measurementDefault) {
                                Text("Hours").tag(Int16(1))
                                Text("Units").tag(Int16(2))
                            }//: PICKER
                            .pickerStyle(.segmented)
                            
                            Button {
                                showCEMeasurementHelpAlert = true
                            } label: {
                                Label("Help me choose", systemImage: "questionmark.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.title3)
                            }//: BUTTON
                            .padding()
                            
                        }//: HSTACK
                        
                        if credential.measurementDefault == 2 {
                            HStack {
                                Text("Clock Hours Per Unit:").accessibilityHidden(true)
                                    .font(.system(size: 12))
                                    .bold()
                                TextField(
                                    "Hours Per Unit",
                                    value: $credential.defaultCesPerUnit,
                                    formatter: twoDigitDecimalFormatter
                                )
                                .frame(maxWidth: 45)
                                .keyboardType(.decimalPad)
                                .submitLabel(.done)
                                .onSubmit {
                                    dismissKeyboard()
                                }
                            }//: HSTACK
                        }//: IF
                    }//: VSTACK
                }//: GROUP
                
                if paidStatus == .proSubscription {
                    Group {
                        VStack(alignment: .leading) {
                            Text("Special CE Category Assignments")
                                .bold()
                                .padding(.bottom, 5)
                            Text("If your licensing/credentialing body requires a certain number of hours of a particular type of continuing education each renewal period, like ethics or law, use this section to create and assign those types so that the app can track your progress in meeting any requirements.")
                                .font(.caption)
                            
                            Button {
                                showSpecialCECatsManagementSheet = true
                            } label: {
                                if let anyAssignedSpecialCats = credential.specialCats as? Set<SpecialCategory> {
                                    if anyAssignedSpecialCats.isEmpty {
                                        Text("Assign Special Category")
                                    } else {
                                        let allAssignments = anyAssignedSpecialCats.map(\.specialName).joined(separator: ", ")
                                        Text("Assigned: \(allAssignments)")
                                    }
                                }
                            }//: BUTTON
                            .padding(.top, 5)
                            
                        }//: VSTACK
                    }//: GROUP (Special CE Categories)
                } else {
                    PaidFeaturePromoView(
                        featureIcon: "list.bullet.clipboard.fill",
                        featureItem: "Credential-Specific CEs",
                        featureUpgradeLevel: .ProOnly
                    )
                }//: IF ELSE
                
                
            }//: SECTION
            
        }//: GROUP
        // MARK: - SHEETS
        // Issuer Sheet
        .sheet(isPresented: $showIssuerListSheet) {
            IssuerListSheet(dataController: dataController, credential: credential)
        }//: SHEET
        
        .sheet(isPresented: $showSpecialCECatsManagementSheet) {
            SpecialCECatsManagementSheet(dataController: dataController, credential: credential)
        }//: SHEET
        
        // MARK: - ALERTS
        .alert("Choosing Default CE Units", isPresented: $showCEMeasurementHelpAlert) {
            Button("OK", role: .cancel, action: {})
        } message: {
            Text("When you complete a CE activity you are awarded credit, which is either the amount of time spent in the activity (contact hours) or units, which is a predetermined amount of clock time hours. For example, completing a one hour activity would earn you either 1 contact hour or 0.1 units (assuming the standard of 10 hours per unit). If unsure which to choose, stay with hours and check with your credential issuer as to what they require.")
        }
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    BasicCredentialInfoView(credential: .example)
    
}

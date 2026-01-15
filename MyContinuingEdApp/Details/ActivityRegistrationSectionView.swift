//
//  ActivityRegistrationView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/13/26.
//

import SwiftUI

/// View with UI controls for CeActivity properties related to activity registration.  If the toggle is set to "on" (true),
/// then a disclosure group with additional controls will appear so the user can enter in things like the
/// registration website, date on which they registered, and a list of things they may need to bring to the event.
///
/// - Parameters:
///     - activity: CeActivity that is passed in from the parent view for which registration details are needed
struct ActivityRegistrationSectionView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    // MARK: - BODY
    var body: some View {
        Section("CE Registration") {
            Toggle("Registration Required?", isOn: $activity.registrationRequiredYN)
            
            if activity.registrationRequiredYN {
                DisclosureGroup("Registration Details") {
                    VStack {
                        // MARK: WEBSITE
                        WebSiteEntryView(
                            propertyURLString: $activity.ceRegistrationURL,
                            textEntryLabel: "Registration Page",
                            textEntryPrompt: "Enter the web address for registering for this activity.",
                            linkLabel: "Registration Page"
                        )
                        
                        Divider()
                        
                        // MARK: Registration Deadline
                        Toggle("Registration Deadline?", isOn: $activity.registrationDeadlineYN)
                        
                        if activity.registrationDeadlineYN {
                            DatePicker("Registration Deadline:", selection: $activity.ceRegistrationDeadline, displayedComponents: .date)
                        }//: IF
                        
                        Divider()
                        
                        // MARK: Registered Date
                        DatePicker(selection: $activity.ceRegisteredOn, displayedComponents: .date) {
                            Text("Registered On:")
                        }//: DATE PICKER
                        
                        Divider()
                        
                        // MARK: Items To Bring
                        VStack {
                            Text("Items To Bring To Event:")
                                .font(.headline)
                            TextField(
                                "Remember To Bring",
                                text: $activity.ceItemsToBring,
                                axis: .vertical
                            )
                            .frame(minHeight: 75) // TODO: check in simulator
                            .onSubmit {
                                dismissKeyboard()
                            }//: ON SUBMIT
                            
                            Text("The app will remind you to bring anything you type into this field prior to the activity so you don't forget. 😎")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                        }//: VSTACK
                        
                        Divider()
                        
                        // MARK: Notes
                        Text("Note: if there is a registration fee assessed for attending, enter that amount into the activity cost field, which is in a separate section below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                    }//: VSTACK
                }//: DISCLOSURE GROUP
            }//: IF
            
        }//: SECTION
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ActivityRegistrationSectionView(activity: .example)
}

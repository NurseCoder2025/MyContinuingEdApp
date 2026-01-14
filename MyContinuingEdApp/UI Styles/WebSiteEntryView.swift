//
//  WebSiteEntryView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/13/26.
//
// Created this subview so that it can be used throughout the app for any
// object or CoreData entity.  Simply use an @State property in the parent view
// to connect the @Binding property to and pass in the desired string value.

import SwiftUI

/// This child view is intended to be used for entering/editing web URL strings
/// for any given object and then,
/// if the string represents a valid URL, displaying a Link so that the user can navigate to the location in their
/// default web browser.
/// - Parameters:
///     - textEntryLabel: String for the TextField control label value
///     - textEntryPrompt: String value for the TextField's prompt parameter
///     - linkLabel: String value for the Link control's label value (once a valid URL is made)
///
/// When the view is first loaded, if the computed property websiteURL returns a valid URL from the passed
/// in string argument, then a Link field is shown along with a button to edit the address.  Tapping the button
/// will change the showWebURLTextField to true and that will trigger a screen redraw with only the TextField
/// control showing so that the user can edit the address.  Upon submitting the new value, if the new string
/// represents a valid link then only the Link and button controls will be shown.  Should an invalid string be
/// entered then an alert will pop up to ask the user to check the address they are entering and enter a valid
/// one.
///
/// This way the user sees either just the TextField control or the Link and edit link button.
struct WebSiteEntryView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @Binding var propertyURLString: String
    
    // Properties for customizing text describing the website being
    // edited/viewed by the user in this view
    let textEntryLabel: String
    let textEntryPrompt: String
    let linkLabel: String
    
    @State private var showWebURLTextField: Bool = false
    @State private var showWebsiteLink: Bool = false
    @State private var showInvalidURLAlert: Bool = false
    
    // MARK: - COMPUTED PROPERTIES
    /// Computed property that returns a URL object created from
    /// the newURLString pararmeter using the DataController method
    /// createURLFromString method.
    var websiteURL: URL? {
        return dataController.createURLFromString(propertyString: propertyURLString)
    }//: websiteURL
    
    // MARK: - BODY
    var body: some View {
            // Will show ONLY either the TextField or the VStack with Link
        Group {
            // MARK: - URL ENTRY
            if websiteURL == nil || showWebURLTextField {
                TextField(
                    textEntryLabel,
                    text: $propertyURLString,
                    prompt: Text(textEntryPrompt)
                )
                .onSubmit {
                    if websiteURL != nil {
                        showWebsiteLink = true
                        showWebURLTextField = false
                        dismissKeyboard()
                    } else {
                        showInvalidURLAlert = true
                    }
                }//: ON SUBMIT
            } else if websiteURL != nil || showWebsiteLink {
                // MARK: - LINK VIEW
                VStack{
                    if let siteURL = websiteURL {
                        HStack {
                            Link(linkLabel, destination: siteURL)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square.fill")
                                .foregroundStyle(Color(.yellow))
                        }//: HStack
                        .frame(minWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                    }//: IF LET
                    
                    
                    // MARK: Edit URL Button
                    Button {
                        showWebURLTextField.toggle()
                    } label: {
                        Label("Edit Web Address", systemImage: "pencil")
                    }//: BUTTON
                    .buttonStyle(.borderedProminent)
                }//: VSTACK
            }//: IF ELSE
        }//: GROUP
         // MARK: - ALERTS
         .alert("Invalid Website Address", isPresented: $showInvalidURLAlert) {
         } message: {
             Text("You entered a website address for the activity that appears to be invalid. Please double-check the URL and enter it again.")
         }//: ALERT
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    WebSiteEntryView(
        propertyURLString: .constant("www.google.com"),
        textEntryLabel: "Activity Website",
        textEntryPrompt: "If this activity has a website, enter it here",
        linkLabel: "Activity Website"
    )
        .environmentObject(DataController(inMemory: true))
}

//
//  ContactDeveloperView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/18/25.
//

import MessageUI
import SwiftUI

struct ContactDeveloperView: View {
    // MARK: - PROPERTIES
    @State private var showMailSheet: Bool = false
    @State private var showMailAlert: Bool = false
    
    // Email Alert properties
    @State private var emailAlertTitle: String = ""
    @State private var emailAlertMessage: String = ""
    
    // TODO: Update developerEmail with address once available
    let developerEmail: String = ""
    @State private var emailSubject: String = ""
    
    // MARK: - BODY
    var body: some View {
        GroupBox {
            Menu {
                // Feedback Link
                Button {
                    emailSubject = "Feedback / Comments"
                    sendMail()
                } label: {
                    Text("Give Feedback")
                }//: BUTTON
                
                // Bug Report
                Button {
                    emailSubject = "Bug Encountered"
                    sendMail()
                } label: {
                    Text("Report Bug")
                }//: BUTTON
                
                // Other Issue
                Button {
                    emailSubject = "Other Issue"
                    sendMail()
                } label: {
                    Text("Other Issue")
                }//: BUTTON
                
            } label: {
                Label("Contact Developer", systemImage: "envelope.fill")
            }//: MENU
        } label: {
            SettingsHeaderView(headerText: "Contact Us", headerImage: "bubble.left.and.bubble.right.fill")
        }
        // MARK: - SHEETS
        .sheet(isPresented: $showMailSheet) {
            ComposeEmailView(
                developerEmail: developerEmail,
                subject: emailSubject) { emailError in
                    if emailError {
                        emailAlertTitle = "Message NOT Sent"
                        emailAlertMessage = "Either the mail failed to send (check network connection and retry) or the message was saved to your drafts folder."
                        showMailAlert = true
                    }
                }
        }//: SHEET
        
        // MARK: - ALERTS
        .alert(emailAlertTitle, isPresented: $showMailAlert) {
        } message: {
            Text(emailAlertMessage)
        }//: ALERT
        
    }//: BODY
    
    // MARK: - METHODS
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            showMailSheet.toggle()
        } else {
            emailAlertTitle = "Mail services are not available."
            emailAlertMessage = "Please add & configure your email account in Settings."
            showMailAlert.toggle()
        }
    }//: sendMail()
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ContactDeveloperView()
}

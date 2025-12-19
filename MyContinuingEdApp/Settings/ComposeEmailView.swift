//
//  ComposeEmailView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/18/25.
//

import MessageUI
import SwiftUI
import UIKit

/// Struct conforming to UIViewControllerRepresentable that will display the email composer sheet when called.
/// - Parameters:
///     - developerEmail: String representing the developer email that the message will be pre-populated with
///     - subject: String representing the purpose of the email (set in ContactDeveloperView)
///
/// The delegate used in conjunction with this struct is final class MailCoordinator which sets the Boolean value for the
/// emailAlert closure property.
struct ComposeEmailView: UIViewControllerRepresentable {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    
    let developerEmail: String
    let subject: String
    
    // MARK: - CLOSURES
    var emailAlert: (Bool) -> Void
    
    // MARK: - METHODS
    func makeCoordinator() -> MailCoordinator {
        MailCoordinator(parent: self)
    }
    
    /// Method for creating the email composer sheet that will be used by the user for communicating with the
    /// developer.
    /// - Parameter context: instance of ComposeEmailView (UIViewControllerRepresentable)
    /// - Returns: MFMailComposeViewController
    ///
    /// This method also sets the recipient and subject fields to values set in the ContactDeveloperView. A
    /// different subject value will be sent in, depending on which button the user taps on.
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients([developerEmail])
        mailComposer.setSubject(subject)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        
    }
    
    
}//: STRUCT

// MARK: - COORDINATOR DELEGATE
/// Delegate for the ComposeEmailView struct.  Sets the Boolean for the emailAlert closure in ComposeEmailView depending
/// on the result returned from the user trying to send the message.
/// - Parameters:
///     - parent: ComposeEmailView struct instance
final class MailCoordinator: NSObject, MFMailComposeViewControllerDelegate {
    let parent: ComposeEmailView
    
    // Methods
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        switch result {
        case .failed:
            parent.emailAlert(true)
        case .saved:
            parent.emailAlert(true)
        default:
            parent.dismiss()
        }
    }
    
    // MARK: - INIT
    init(parent: ComposeEmailView) {
        self.parent = parent
    }//:INIT
    
}//: class MAIL COORDINATOR

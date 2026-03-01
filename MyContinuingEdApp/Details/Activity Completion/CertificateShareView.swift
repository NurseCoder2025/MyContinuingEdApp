//
//  CertificateShareView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/13/25.
//

import SwiftUI

struct CertificateShareView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    
    @StateObject private var viewModel: ViewModel
    
    // MARK: - BODY
    var body: some View {
        switch viewModel.sharingLinkStatus {
        case .loading:
            HStack {
                Text("Preparing certificate for export/sharing...")
                    .font(.caption)
                ProgressView("Loading...")
                    .progressViewStyle(.circular)
            }//: HSTACK
        case .loaded:
            if let url = viewModel.fileShareURL {
                ShareLink(item: url) {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                } //: SHARE LINK
            }//: IF LET
        case .error:
            VStack {
                Text("Loading Certificate Data for Export Failed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    viewModel.sharingLinkStatus = .loading
                    viewModel.loadCertData(for: activity)
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise.circle.fill")
                }//: BUTTON
                .buttonStyle(.bordered)
            }//: VSTACK
             // MARK: - ALERTS
            .alert(viewModel.errorAlertTitle, isPresented: $viewModel.showErrorAlert) {
                    Button("OK"){}
                } message: {
                    Text(viewModel.errorAlertMessage)
                }//: ALERT
        }//: SWITCH
        
  }//: BODY
    
    // MARK: - INIT
    
    init(activity: CeActivity, certBrain: CertificateBrain) {
        self.activity = activity
        
        let viewModel = ViewModel(activity: activity, certBrain: certBrain)
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }//: INIT
    
}//: STRUCT



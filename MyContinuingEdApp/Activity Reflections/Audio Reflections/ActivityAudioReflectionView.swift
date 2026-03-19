//
//  ActivityAudioReflectionView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/20/25.
//

import AVFoundation
import SwiftUI

struct ActivityAudioReflectionView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var reflection: ActivityReflection
    
    @StateObject var viewModel: ViewModel
    
    
    // MARK: - COMPUTED PROPERTIES
    var paidStatus: PurchaseStatus {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return .proSubscription
        case PurchaseStatus.basicUnlock.id:
            return .basicUnlock
        default:
            return .free
        }
    }//: paidStatus
    
    // MARK: - BODY
    var body: some View {
        if paidStatus != .proSubscription {
            PaidFeaturePromoView(
                featureIcon: "waveform.and.mic",
                featureItem: "Audio Reflection",
                featureUpgradeLevel: .ProOnly
            )
        } else {
            // MARK: Audio Section
            Section("Audio Reflection") {
                
            }//: SECTION - Audio Reflection
        }//: IF ELSE
    }//: BODY
    
    // MARK: - INIT
    init(
        dataController: DataController,
        for reflection: ActivityReflection,
        audiBrain: AudioReflectionBrain
    ) {
        self.reflection = reflection
        let newViewModel = ViewModel(brain: audiBrain)
        _viewModel = StateObject(wrappedValue: newViewModel)
    }//: INIT
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    ActivityAudioReflectionView(dataController: .preview, for: .example, audiBrain: .preview)
}

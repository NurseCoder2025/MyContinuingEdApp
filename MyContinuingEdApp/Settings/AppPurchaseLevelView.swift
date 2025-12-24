//
//  AppPurchaseLevelView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/15/25.
//

import SwiftUI

struct AppPurchaseLevelView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - COMPUTED PROPERTIES
    var appPurchaseLevelText: String {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return "CE Cache Pro (\(dataController.currentSubscriptionType.capitalized))"
        case PurchaseStatus.basicUnlock.id:
            return "CE Cache Basic"
        default:
            return "CE Cache FREE"
        }//: SWITCH
    }//: appPurchaseLevelText
    
    var purchaseLevelDescription: String {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return "As a Pro subscriber, you get access to ALL app features and exclusive pro-level updates in the future. Thank you for your support!"
        case PurchaseStatus.basicUnlock.id:
            return "Thank you for your support! You can now track an unlimited number of CE activities for a single credential, save CE certificates and write reflections on your learning. For all app features, subscribe to a Pro plan."
        default:
            return "As a Free user, you are able to try out essential features of the app by creating three tags and three CE activities.  If you find the app helpful, upgrade to the paid option that is right for you."
        }
    }//: purchaseLevelDescription
    
    // MARK: - BODY
    var body: some View {
        GroupBox(label: SettingsHeaderView(headerText: "Purchase Level", headerImage: "info.circle")) {
            
            Text(appPurchaseLevelText)
                .font(.headline)
                .bold()
                .padding(.vertical, 5)
            
            Text(purchaseLevelDescription)
                .font(.caption)
                .multilineTextAlignment(.leading)
            
        }//: GroupBox
        .accessibilityLabel(Text("The version of the app you currently are using is \(appPurchaseLevelText)"))
        .accessibilityHint(Text(purchaseLevelDescription))
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    AppPurchaseLevelView()
}

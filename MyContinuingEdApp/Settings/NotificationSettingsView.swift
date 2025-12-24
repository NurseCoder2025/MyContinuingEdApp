//
//  NotificationSettingsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/17/25.
//

import SwiftUI

struct NotificationSettingsView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
 
    // MARK: - BODY
    var body: some View {
        VStack {
            // Notification Day settings
            GroupBox {
                VStack {
                    // Description for user
                    Text("CE Cache will notify you twice about upcoming dates pertaining to CE activities, credential renewal, and, if a subscriber, any disciplinary action deadlines. Use this section to designate how far in advance you want to be notified.")
//                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                        .padding([.leading, .trailing], 20)
                    
                    // Primary Notification
                   SettingsSliderView(
                    sliderValue: $dataController.primaryNotificationDays,
                    minValue: 30,
                    maxValue: 180,
                    stepValue: 1,
                    headerText: "Primary Alert",
                    minImageLabel: "hourglass.bottomhalf.fill",
                    maxImageLabel: "hourglass.tophalf.fill"
                   )
                   .padding(.top, 5)
                    
                    Divider()
                    
                    // Secondary Notification
                   SettingsSliderView(
                    sliderValue: $dataController.secondaryNotificationDays,
                    minValue: 2,
                    maxValue: 29,
                    stepValue: 1,
                    headerText: "Secondary Alert",
                    minImageLabel: "clock.badge.exclamationmark.fill",
                    maxImageLabel: "deskclock.fill"
                   )
                    
                }//: VSTACK
            } label: {
                SettingsHeaderView(headerText: "Notification Intervals", headerImage: "calendar.badge.clock.rtl")
            }//: GROUPBOX
            .padding(.bottom, 15)
        
            // Notifications to show toggles
            GroupBox {
                VStack(spacing: 0) {
                    Text("Select which notifications you would like to receive.")
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    VStack {
                        Toggle("Expiring CE Activity Alerts", isOn: $dataController.showExpiringCesNotification)
                        
                        Toggle("Renewal Period Ending Alerts", isOn: $dataController.showRenewalEndingNotification)
                        
                        Toggle("Renewal Late Fee Alerts", isOn: $dataController.showRenewalLateFeeNotification)
                        
                        if dataController.purchaseStatus == PurchaseStatus.proSubscription.id {
                            Toggle("Disciplinary Action Notifications", isOn: $dataController.showDAINotifications)
                        }
                    }//: VStack
                }//: VSTACK
            } label: {
                SettingsHeaderView(headerText: "Notification Toggles", headerImage: "switch.2")
            }//: GROUP BOX

            
        }//: VSTACK
        
    }//: BODY
}//: STRUCT

 // MARK: - PREVIEW
#Preview {
    NotificationSettingsView()
        .environmentObject(DataController.preview)
}

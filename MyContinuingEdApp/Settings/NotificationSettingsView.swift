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
                    Text("CE Cache will notify you twice about upcoming dates pertaining to CE activities, credential renewal, and, if a subscriber, any disciplinary action and reinstatement related deadlines. Use this section to designate how far in advance you want to be notified.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                        .padding([.leading, .trailing], 20)
                    
                    // Primary Notification
                   SettingsSliderView(
                    sliderValue: $dataController.primaryNotificationDays,
                    minValue: 30,
                    maxValue: 180,
                    stepValue: 1,
                    valueLabel: "days",
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
                    valueLabel: "days",
                    headerText: "Secondary Alert",
                    minImageLabel: "clock.badge.exclamationmark.fill",
                    maxImageLabel: "deskclock.fill"
                   )
                    
                }//: VSTACK
            } label: {
                SettingsHeaderView(headerText: "Notification Intervals", headerImage: "calendar.badge.clock.rtl")
            }//: GROUPBOX
            .padding(.bottom, 15)
            
            // Live Event Alert Sliders
            GroupBox {
                VStack {
                    Text("""
                         For any live events that have a definitive start time, Ce Cache will generate up to two reminders for you on the day they take place. If you only want one reminder, then set the corresponding slider to 0.
                         
                         For the purposes of these settings, live events include CE activities and conferences, as well as events tied to credential reinstatement (Pro subscribers only).
                         """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                        .padding([.leading, .trailing], 20)
                    
                    // First Alert
                    SettingsSliderView(
                        sliderValue: $dataController.firstLiveEventAlert,
                        minValue: 0.0,
                        maxValue: 480.0,
                        stepValue: 30,
                        valueLabel: "minutes",
                        headerText: "First alert",
                        minImageLabel: "hourglass.tophalf.fill",
                        maxImageLabel: "hourglass.bottomhalf.fill"
                    )
                    .padding(.top, 5)
                    
                    Divider()
                    
                    // Second Alert
                    SettingsSliderView(
                        sliderValue: $dataController.secondLiveEventAlert,
                        minValue: 0.0,
                        maxValue: 120.0,
                        stepValue: 15,
                        valueLabel: "minutes",
                        headerText: "Second alert",
                        minImageLabel: "clock.badge.exclamationmark.fill",
                        maxImageLabel: "deskclock.fill"
                    )
                    
                    
                }//: VSTACK
                
            } label: {
                SettingsHeaderView(headerText: "Live CE Activity Alerts", headerImage: "person.2.wave.2")
            }
            .padding(.bottom, 15)
        
            // Notifications to show toggles
            GroupBox {
                VStack(spacing: 0) {
                    Text("Select which notifications you would like to receive.")
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    VStack {
                        Toggle("Upcoming Live Event Alerts", isOn: $dataController.showAllLiveEventAlerts)
                        
                        Toggle("Expiring CE Activity Alerts", isOn: $dataController.showExpiringCesNotifications)
                        
                        Toggle("Renewal Period Ending Alerts", isOn: $dataController.showRenewalEndingNotifications)
                        
                        Toggle("Renewal Late Fee Alerts", isOn: $dataController.showRenewalLateFeeNotifications)
                        
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

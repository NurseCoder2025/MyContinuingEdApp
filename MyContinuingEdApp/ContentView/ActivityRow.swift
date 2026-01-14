//
//  ActivityRow.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/19/25.
//

import Foundation
import SwiftUI

struct ActivityRow: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // computed property that returns the expiration status of the activity
    var expiration: ExpirationType {
        return activity.expirationStatus
    }
    
    
    // MARK: - BODY
    var body: some View {
        NavigationLink(value: activity) {
            HStack {
                // This block shows a different icon depending on whether the activity
                // has been completed by the user, and if not, whether the activity
                // has expired or will be expiring soon
                // MARK: - STATUS ICON
                VStack(alignment: .leading) {
                    if activity.activityCompleted == true {
                        Image(systemName: "checkmark.seal.fill")
                            .imageScale(.large)
                            .foregroundStyle(Color.green)
                            .accessibilityLabel("Activity completed")
                    }
                    if expiration == .expiringSoon {
                        // Extra padding was required for this icon due to it
                        // appearing misaligned when other entries were displaying
                        // the checkmark icon.
                        Image(systemName: "hourglass")
                            .imageScale(.large)
                            .padding(.trailing, 8)
                            .padding(.leading, 2)
                            .accessibilityLabel("Expires soon")
                    } else if expiration == .expired {
                        Image(systemName: "x.circle.fill")
                            .imageScale(.large)
                            .accessibilityLabel("Expired")
                    } else if expiration == .finalDay {
                        Image(systemName: "clock.badge.exclamation")
                            .imageScale(.large)
                            .accessibilityLabel("Activity expires after today")
                    } else if expiration == .stillValid  || expiration == .liveActivity {
                        // This image is just used as a blank filler to keep things aligned
                        // if the activity does not meet any of the above criteria.
                        Image(systemName: "book.fill")
                            .imageScale(.large)
                            .opacity(0)
                            .accessibilityLabel("Activity currently valid")
                    } //: IF - ELSE Block
                } //: VSTACK
                .padding(.trailing, 4)
               
                
                // VSTACK for name and tags
                // MARK: - NAME & Tags
                VStack(alignment: .leading) {
                    // Activity Name
                    Text(activity.ceTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Tags
                    Text(activity.allActivityTagString)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } //: VSTACK
               
            Spacer()
            
                // MARK: - Completion & Expiration Status
            VStack(alignment: .trailing) {
                // 8-12-25 Improvement: Placed "Completed" and "exp" date in
                // an if-else statement so that the expiration date is hidden
                // once an activity is marked completed by the user.
                if activity.activityCompleted {
                    Text("Completed")
                        .font(.body.smallCaps())
                        .foregroundStyle(Color.green)
                    
                    if let completionDate = activity.dateCompleted {
                        Text("on \(completionDate.formatted(date: .numeric, time: .omitted))")
                            .accessibilityLabel("completed on \(completionDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .italic()
                    } else {
                        Text("Need date completed...")
                            .font(.caption)
                            .italic()
                    }
                } else {
                    if let expiration = activity.expirationDate {
                        Text("Expires on")
                            .foregroundStyle(.red)
                        Text("\(expiration.formatted(date: .numeric, time: .omitted))")
                            .accessibilityLabel(Text("Expires on \(expiration.formatted(date: .abbreviated, time: .omitted))"))
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .bold()
                    } else if activity.isLiveActivity, let setTime = activity.startTime {
                        VStack(spacing: 2) {
                            Text(setTime.formatted(date: .omitted, time: .shortened))
                                .bold()
                        
                                Text(setTime.formatted(date: .numeric, time: .omitted))
                          
                        }//: VSTACK
                        .font(.subheadline)
                    } else if activity.isLiveActivity {
                        Text("Live Activity")
                            .font(.caption).bold()
                        Text("Need date & time!")
                            .font(.caption)
                            .italic()
                    } else {
                        Text("Expires, no date")
                            .foregroundStyle(.gray)
                            .font(.caption)
                            .italic()
                    }
                } //: IF - ELSE
                
            } //: VSTACK - Expiration date
                
        } //: HSTACK
            
        } //: NAV LINK
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
struct ActivityRow_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRow(activity: .example)
    }
}

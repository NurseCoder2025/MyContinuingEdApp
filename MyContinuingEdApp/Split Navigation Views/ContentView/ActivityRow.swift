//
//  ActivityRow.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/19/25.
//

import Foundation
import SwiftUI

/// View that displays each pertinent info for each CeActivity object in the list shown in ContentView.
///
///- Important: Do not remove the  "book.fill" SF symbol as it is a placeholder that ensures all
///rows are aligned with each other.  The user will never see it due to a 0 opacity modifier being applied
///to it.
///
/// Each row consists of the following: an icon (or placeholder) indicating the completion or expiration
/// status of the activity (if applicable), the name of the activity, any tags associated underneath it,
/// and at the end two lines of text indicating if the activity has been completed, and if so, when.  If not
/// completed, then if the activity is set to expire then that info is shown. Otherwise, the user is shown
/// the date & starting time of the activity if still future; if currently happening, then it will display "In
/// Progress" with the ending time; if past, then the user will just see "Event Over".
///
/// If either the start time or end time properties are nil then the user will be prompted to add those
/// details with the text "Live Activity /n Need Date and Times".  Otherwise, the activity will be assumed
/// to something that will expire, but no expiration date has been provided yet and the user will see
/// "Expires, no date".
struct ActivityRow: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // computed property that returns the expiration status of the activity
    var expiration: ExpirationType {return activity.expirationStatus}
    
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
                // MARK: - COMPLETED ACTIVITIES
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
                    // MARK: - UNCOMPLETED ACTIVITIES
                    // MARK: EXPIRING ACTIVITIES
                    if let expiration = activity.expirationDate {
                        Text("Expires on")
                            .font(.body.smallCaps())
                            .foregroundStyle(.red)
                        Text("\(expiration.formatted(date: .numeric, time: .omitted))")
                            .accessibilityLabel(Text("Expires on \(expiration.formatted(date: .abbreviated, time: .omitted))"))
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .bold()
                        
                        // MARK: Live Activities FUTURE
                    } else if activity.isLiveActivity, let setTime = activity.startTime, setTime > Date.now {
                        VStack(spacing: 2) {
                            Text(setTime.formatted(date: .omitted, time: .shortened))
                                .bold()
                        
                                Text(setTime.formatted(date: .numeric, time: .omitted))
                          
                        }//: VSTACK
                        .font(.subheadline)
                        
                        // MARK: Live Activities IN PROGRESS
                    } else if activity.isLiveActivity, let setTime = activity.startTime, setTime <= Date.now, let endingAt = activity.endTime, endingAt > Date.now {
                        VStack(spacing: 2) {
                            // TODO: Add special color to "In Progress"
                           Text("In Progress")
                                .bold()
                            Text("Ends at \(endingAt.formatted(date: .omitted, time: .shortened))")
                        }//: VSTACK
                        .font(.subheadline)
                        
                        // MARK: Live Activity OVER
                    } else if activity.isLiveActivity, let setTime = activity.startTime, setTime < Date.now, let endingAt = activity.endTime, endingAt < Date.now {
                        VStack(spacing: 2) {
                            // TODO: Check formatting on text
                            Text("Event Over")
                                .bold()
                                .italic()
                                .foregroundStyle(.secondary)
                        }//: VSTACK
                        .font(.subheadline)
                        
                        // MARK: Missing Info
                    } else if activity.isLiveActivity {
                        Text("Live Activity")
                            .font(.caption).bold()
                        Text("Need date & times!")
                            .font(.caption)
                            .italic()
                    } else {
                        // MARK: EXPIRING ACTIVITIES W/ NO INFO
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

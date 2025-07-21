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
                VStack(alignment: .leading) {
                    if activity.activityCompleted != true {
                        if expiration == .expiringSoon {
                            // Extra padding was required for this icon due to it
                            // appearing misaligned when other entries were displaying
                            // the checkmark icon.
                            Image(systemName: "hourglass")
                                .imageScale(.large)
                                .padding(.trailing, 8)
                                .padding(.leading, 2)
                        } else if expiration == .expired {
                            Image(systemName: "x.circle.fill")
                                .imageScale(.large)
                        } else if expiration == .finalDay {
                            Image(systemName: "clock.badge.exclamation")
                                .imageScale(.large)
                        }
                    } else if activity.activityCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .imageScale(.large)
                            .foregroundColor(Color.green)
                    } else {
                        Image(systemName: "book.fill")
                            .imageScale(.large)
                            .opacity(0)
                    } //: IF - ELSE Block
                } //: VSTACK
                .padding(.trailing, 4)
               
                
                // VSTACK for name and tags
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
            
            VStack(alignment: .trailing) {
                Text(activity.ceActivityExpirationDate.formatted(date: .numeric, time: .omitted))
                    .font(.subheadline)
                
                if activity.activityCompleted {
                    Text("Completed")
                        .font(.body.smallCaps())
                        .foregroundColor(Color.green)
                }
            } //: VSTACK - Expiration date
                
        } //: HSTACK
            
        } //: NAV LINK
        
    }
}


// MARK: - PREVIEW
struct ActivityRow_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRow(activity: .example)
    }
}

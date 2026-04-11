//
//  ReinstatementAdditionalItemsView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/8/26.
//

import SwiftUI

struct ReinstatementAdditionalItemsView: View {
    // MARK: - PROPERTIES
    @ObservedObject var reinstatement: ReinstatementInfo
    
    // MARK: - BODY
    var body: some View {
        Section {
            // Background Check
            DisclosureGroup("Background Check") {
                VStack {
                    Toggle("Need Background Check?", isOn: $reinstatement.backgroundCheckYN)
                    Text("Depending upon the credential and how long it has been lapsed, the issuer may require a new criminal background check prior to reinstatement.  Check with them to see if this applies in your situation.")
                        .font(.caption)
                    
                    if reinstatement.backgroundCheckYN {
                        DatePicker(
                            LocalizedStringKey("Background Check Completed"),
                            selection: $reinstatement.riBcCompletedDate, displayedComponents: .date
                        )
                    }//: IF
                }//: VSTACK
            }//: DISCLOSURE
            
            // Interview
            DisclosureGroup("Interview") {
                VStack {
                    Toggle("Interview Needed?", isOn: $reinstatement.interviewYN)
                    Text("In some situations, a credential issuer may require an interview as part of the reinstatement process. Check with your governing body to see if this applies to you.")
                        .font(.caption)
                    
                    if reinstatement.interviewYN {
                        HStack {
                            Text("Scheduled For:")
                            DatePicker(
                                LocalizedStringKey("Interview Date"),
                                selection: $reinstatement.riInterviewScheduled, displayedComponents: [.hourAndMinute, .date]
                            )
                            
                        }//: HSTACK
                    }//: IF
                }//: VSTACK
            }//: DISCLOSURE
            
            // Test
            DisclosureGroup("Knowledge Test") {
                VStack {
                    Toggle("Test Needed?", isOn: $reinstatement.additionalTestingYN)
                    Text("Depending on circumstances, a written knowledge test may be required to reinstate the credential. Check with the credential issuer to confirm if this is required in your situation.")
                        .font(.caption)
                    
                    if reinstatement.additionalTestingYN {
                        HStack {
                            Text("Scheduled For:")
                            DatePicker(LocalizedStringKey("Test Date"), selection: $reinstatement.riAdditionalTestDate, displayedComponents: [.hourAndMinute, .date])
                        }//: HSTACK
                        
                        TextField("Testing Notes", text: $reinstatement.riAdditionalTestNotes, axis: .vertical)
                        
                        TextField("Results", text: $reinstatement.riAdditionalTestResults, axis: .vertical)
                    }//: IF
                }//: VSTACK
            }//: DISCLOSURE
            
        } header: {
            Text("Additional Items")
        } footer: {
            Text("If your credential issuer requires anything additional such as a test, interview, background check, indicate that in this section.")
        }//: SECTION
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    ReinstatementAdditionalItemsView(reinstatement: .example)
}

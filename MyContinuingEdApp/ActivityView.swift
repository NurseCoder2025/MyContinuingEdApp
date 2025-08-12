//
//  ActivityView.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/18/25.
//

import SwiftUI

struct ActivityView: View {
    // MARK: - Properties
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    
    // MARK: - BODY
    var body: some View {
        // formatting contact hours value to 2 decimal places for use in textfield
        let hoursFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        // creating a formatter for currency values to be used in another textfield
        let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            
            return formatter
        }()
        
        Form {
            // MARK: - HEADER section
            Section {
                VStack(alignment: .leading) {
                    TextField("Title:", text: $activity.ceTitle, prompt: Text("Enter the activity name here"))
                        .font(.title)
                    
                    Text("**Modified:** \(activity.ceActivityModifiedDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)
                    
                    Text("**Expiration Status:** \(activity.expirationStatus.rawValue)")
                        .foregroundStyle(.secondary)
                } //: VSTACK (title and modification date)
                
                Picker("My Rating:", selection: $activity.evalRating) {
                    Text(ActivityRating.terrible.rawValue).tag(Int16(0))
                    Text(ActivityRating.poor.rawValue).tag(Int16(1))
                    Text(ActivityRating.soSo.rawValue).tag(Int16(2))
                    Text(ActivityRating.interesting.rawValue).tag(Int16(3))
                    Text(ActivityRating.lovedIt.rawValue).tag(Int16(4))
                }
                // MARK: Tag Menu
                Menu {
                    // Selected tags
                    ForEach(activity.activityTags) { tag in
                        Button {
                            // Tapping button will remove tag for the specific activity and into the "missing tags" set
                            activity.removeFromTags(tag)
                        } label: {
                            Label(tag.tagTagName, systemImage: "checkmark")
                        } //: Button + Label
                        
                    }//: LOOP
                    
                    
                    // Unselected tags
                    let remainingTags = dataController.missingTags(from: activity)
                    
                    if remainingTags.isNotEmpty {
                        Divider()
                        
                        Section("Add Tags") {
                            ForEach(remainingTags) { tag in
                                Button {
                                    activity.addToTags(tag)
                                } label: {
                                    Text(tag.tagTagName)
                                } //: BUTTON + label
                                
                            } //: LOOP
                            
                        } //: SECTION
                    } //: IF Statement
                    
                    
                } label: {
                    Text(activity.allActivityTagString)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil, value: activity.allActivityTagString)
                } //: MENU + Label
                
            } //: SECTION - Header
                // MARK: - Description & Expiration
                Section("Description & Activity Expiration") {
                    TextField("Description:", text: $activity.ceDescription, prompt: Text("Enter a description of the activity"), axis: .vertical)
                        .keyboardType(.default)
                    
                    DatePicker("Expires On", selection: $activity.ceActivityExpirationDate, displayedComponents: [.date])
                        .onChange(of: activity.ceActivityExpirationDate) { _ in
                            updateActivityStatus(status: activity.expirationStatus)
                        }
                } //: Description Subsection
                
            // MARK: - Hours & Cost
                Section("Contact Hours & Cost") {
                    HStack {
                        HStack {
                            Text("Contact Hours:")
                                .bold()
                                .padding(.trailing, 5)
                            TextField("Contact Hours:", value: $activity.contactHours, formatter: hoursFormatter , prompt: Text("# hours awarded"))
                                .keyboardType(.decimalPad)
                    
                        } //: HSTACK
                        
                        Divider()
                        
                        HStack {
                            Text("Cost:")
                                .bold()
                                .padding(.trailing, 20)
                            TextField("Activity Cost:", value: $activity.cost, formatter: currencyFormatter, prompt: Text("Cost/Fees"))
                                .keyboardType(.decimalPad)
                                
                        } //: HSTACK
                    }
                } //: Contact Hours & Cost subsection
            
            // MARK: - CE Type and Activity Format
            Section("CE Awarded & Activity Format") {
                TextField("Type of CE Awarded", text: $activity.ceActivityCEType, prompt: Text("CME, Nursing CE, CEU, etc."))
                
                TextField("Activity Format", text: $activity.ceActivityFormatType, prompt: Text("Recording? Live webinar? Conference?"))
                
            }//: CE Type and Activity Format subsection
            // MARK: - Activity Completion
            Section("Activity Completion") {
                Toggle("Activity Completed?", isOn: $activity.activityCompleted)
                if activity.activityCompleted {
                    DatePicker("Date Completed", selection: $activity.ceActivityCompletedDate, displayedComponents: [.date])
                    
                    TextField("What I Learned", text: $activity.ceActivityWhatILearned, prompt: Text("What did you learn from this activity?"),axis: .vertical )
                } // IF activity completed...
                
            }//: Activity Completion Section
                
            
            
        } //: FORM
        .onAppear {
            updateActivityStatus(status: activity.expirationStatus)
        } //: onAppear
        .disabled(activity.isDeleted)
        .onReceive(activity.objectWillChange) { _ in
            dataController.queueSave()
        } //: onReceive
        .onChange(of: activity.dateCompleted) { _ in
            dataController.assignActivitiesToRenewalPeriod()
        }
    }//: BODY
    
    
    // MARK: - Activity Specialty Methods
    /// The updateActivityStatus function exists to enable filtering functionality in the DataController. -->
    /// Adding this function in order to automatically assign the computed ExpirationType value from the CEActivity-Core
    /// DataHelper file (see bottom extension) to the direct property in Core Data.  Need to use this in order to
    /// properly filter activities by expiration status (type) in the DataController.
    func updateActivityStatus(status: ExpirationType) {
        activity.currentStatus = status.rawValue
    }
}

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(activity: .example)
    }
}

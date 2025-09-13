#  Defunct Code

### From the RenewalPeriodView file:

            .onAppear {
                // Adding this code to fix a bug where the sheet view will
                // not show the computed name of the renewal period upon
                // first loading/opening the app.
                let context = dataController.container.viewContext
                let objectID = renewalPeriod.objectID
                if let refreshed = try? context.existingObject(
                    with: objectID) as? RenewalPeriod {
                    renewalPeriod.periodStart = refreshed.periodStart
                    renewalPeriod.periodEnd = refreshed.periodEnd
                }
                
            } //: ON APPEAR

--> This code did NOT work and even caused a fatal error crash.



    /// The updatePeriodName creates a specific text string for a given renewal period
    /// object, either returning just a single year or a range of years.  This function
    /// will then update the periodName property for the RenewalPeriod class.
    private func updatePeriodName() {
        guard periodStart != nil else { return }
        
        let startYear = periodStart?.yearString ?? ""
        let endYear = periodEnd?.yearString ?? ""
        let newRenewalPeriodName: String
        
        if startYear == endYear || endYear.isEmpty {
            newRenewalPeriodName = "\(startYear) Renewal"
        } else  {
            newRenewalPeriodName = "\(startYear) - \(endYear) Renewal"
        }
        
        if periodName != newRenewalPeriodName {
            periodName = newRenewalPeriodName
        }
        
    } //: updatePeriodName()



                // If NO credentials have been entered yet
                if allCredentials.isEmpty {
                    Section {
                        ForEach(convertedRenewalFilters) { filter in
                            NavigationLink(value: filter) {
                                Label(filter.name, systemImage: filter.icon)
                                    .badge(filter.renewalPeriod?.renewalCurrentActivities.count ?? 0)
                                    .contextMenu {
                                        // Edit Renewal Period
                                        Button {
                                            editRenewalPeriod(filter)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        // Delete Renewal Period
                                        Button(role: .destructive) {
                                            renewalToDelete = filter.renewalPeriod
                                            showDeletingRenewalAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }//: CONTEXT MENU
                            }//: NAV LINK
                            
                        }//: LOOP
                        
                        
                    } header: {
                        HStack {
                            Text("Renewal Periods")
                            Spacer()
                            Button {
                                showRenewalPeriodView = true
                            }label: {
                                Label("Add Renewal Period", systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            }
                        }//: HSTACK
                    }//: SECTION
                    
                }//: IF

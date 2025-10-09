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


### Add Credential button:
    Button {
        showCredentialSheet = true
    } label: {
        Label("Add Credential", systemImage: "square.and.at.rectangle.fill")
    }


### Special CE Cat functions and other items no longer needed
### From DataController:
    // Ensures a SpecialCategory with name "None" exists
    private func ensureNoneSpecialCategoryExists() {
        let request = SpecialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "None")
        request.fetchLimit = 1
        let count = (try? container.viewContext.count(for: request)) ?? 0
        if count == 0 {
            let noneCat = SpecialCategory(context: container.viewContext)
            noneCat.name = "None"
            noneCat.abbreviation = ""
            noneCat.catDescription = "No special category."
            save()
        }
    }//: FUNC (ensureNoneSpecialCategoryExists)
    
### From the SpecialCategory-CoreDataHelper:
    // Returns all SpecialCategory objects with "None" first
    static func noneFirstOrder(in context: NSManagedObjectContext) -> [SpecialCategory] {
        let request = SpecialCategory.fetchRequest()
        let allCats = (try? context.fetch(request)) ?? []
        let noneCat = allCats.first(where: { $0.specialName == "None" })
        let others = allCats.filter { $0.specialName != "None" }
        if let noneCat = noneCat {
            return [noneCat] + others
        } else {
            return allCats
        }
    }    
    

### From the CeActivity-CoreDataHelper:
    var allSpecialCECats: [SpecialCategory] {
        // Computed property logic:
        // 1. retrieve all credential objects associated with a given activity
        // 2. for each credential, retrieve all special CE categories associated with it
        // 3.  append all special CE categories to a single array and return the array
        
        // defining a SpecialCategory array which will hold all SpecialCategory objects
        var allCredCats: [SpecialCategory] = []
        
        // Getting all Credential objects for a CeActivity (computed property in extension)
        let allActivityCreds = activityCredentials  // [Credential]
        
        // For each Credential, retrieve all SpecialCategory objects and append them to the
        // allCredCats array, which will be returned
        for cred in allActivityCreds {
            let specialCatObjects = cred.specialCats?.allObjects as? [SpecialCategory] ?? []
            if specialCatObjects.isNotEmpty {
                // appending each SpecialCategory object linked to the credential
                // to the allCredCats array
                for object in specialCatObjects {
                    allCredCats.append(object)
                }
            }
            
        }//: LOOP
        
        return allCredCats
    }


### From the CredentialManagementSheet:
    // Computed property that adds the "All" type to the front of the Credential.allTypes array,
    // as well as adding an "s" to the end of all other types
    var allCredentialTypes: [String] {
        var types = [String]()
        let pluralTypes = Credential.allTypes.map { $0 + "s" }
        types.append("All")
        
        for type in pluralTypes {
            types.append(type)
        }
        
        return types
    }
    
    // Computed property that returns a specific icon for each credential type
    var credentialIcons: [String: String] {
        [
            "All": "folder.fill",
            "Licenses": "person.text.rectangle.fill",
            "Certifications": "checkmark.seal.fill",
            "Endorsements": "rectangle.fill.badge.plus",
            "Memberships": "person.2.fill",
            "Others": "questionmark.circle.fill"
        ]
    }


### From the CredentialSheet:
#### Diagnostic code to print out all Credential objects:
        // Print out number of credential objects and their name
//        print("------------------Diagnostic: Credential Objects --------------")
//        let context = dataController.container.viewContext
//        let request = Credential.fetchRequest()
//        let allCreds = (try? context.fetch(request)) ?? []
//        
//        let count = (try? context.count(for: request)) ?? 0
//        print("Total Credential objects: \(count)")
//        print("")
//        
//        for cred in allCreds {
//            print(cred.credentialName)
//        }

#  Ditched Code Snippets 
For reference use ONLY

## From the RenewalPeriod-Core Data Helper file
    // Computed property to automatically create the name of each new renewal period
    var generatedRenewalPeriodName: String  {
        // Get only the year digits for the starting year
        let startingYearString = String(renewalPeriodStart.formatted(date: .numeric, time: .omitted))
        let startingPeriodYear = startingYearString.dropFirst(6)
        
        // Get only the year digits for the ending year
        let endingYearString = String(renewalPeriodEnd.formatted(date: .numeric, time: .omitted))
        let endingPeriodYear = endingYearString.dropFirst(6)
        
        
        if startingPeriodYear == endingPeriodYear {
            return "\(startingPeriodYear) Renewal"
        } else  {
            return "\(startingPeriodYear) - \(endingPeriodYear) Renewal"
        }
        
        
    }


## Unneccessary function from the DataController's calculateCEsEarnedByMonth method:
    /// Method for deleting any and all created placeholder Credentials.  This method was specifically created to handle the potential outcome of
    /// the private method convertCesAwardedToHoursFor(activity), but can be used elsewhere as needed.  However, in order to work only
    /// Credential objects with the name of "Placeholder" will be fetched and deleted.
    private func deleteAllPlaceholderCredentials() {
        let request: NSFetchRequest<Credential> = Credential.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Placeholder")
        
        do {
            let credsToDelete: [Credential] = try container.viewContext.fetch(request)
            for cred in credsToDelete {
                delete(cred)
            }
        } catch {
            print("Failed to fetch placeholder Credentials, and, therefore, can't delete them.")
        }
        
    }//: deleteAllPlaceholderCredentials

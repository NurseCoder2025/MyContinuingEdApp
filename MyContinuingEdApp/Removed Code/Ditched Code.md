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

